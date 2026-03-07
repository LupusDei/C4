import { randomUUID } from 'node:crypto';

const assembleBodySchema = {
  type: 'object',
  required: ['projectId', 'clipAssetIds'],
  properties: {
    projectId: { type: 'string', format: 'uuid' },
    clipAssetIds: {
      type: 'array',
      items: { type: 'string', format: 'uuid' },
      minItems: 1,
      maxItems: 50,
    },
    aspectRatio: { type: 'string', enum: ['16:9', '9:16', '1:1', '4:3'], default: '16:9' },
    enableCaptions: { type: 'boolean', default: false },
    transition: { type: 'string', enum: ['none', 'crossfade', 'fade'], default: 'none' },
  },
};

const assembleResponseSchema = {
  type: 'object',
  properties: {
    jobId: { type: 'string', format: 'uuid' },
    assetId: { type: 'string', format: 'uuid' },
    status: { type: 'string' },
  },
};

export default async function assembleRoutes(fastify) {
  fastify.post('/api/assemble', {
    schema: {
      description: 'Assemble multiple video clips into a single video with optional captions',
      tags: ['assembly'],
      body: assembleBodySchema,
      response: { 202: assembleResponseSchema },
    },
    handler: async (request, reply) => {
      const { projectId, clipAssetIds, aspectRatio, enableCaptions, transition } = request.body;

      // Validate all clips exist and are complete videos
      const clips = await fastify.db('assets')
        .whereIn('id', clipAssetIds)
        .andWhere({ type: 'video', status: 'complete' });

      if (clips.length !== clipAssetIds.length) {
        const foundIds = new Set(clips.map((c) => c.id));
        const missing = clipAssetIds.filter((id) => !foundIds.has(id));
        return reply.code(400).send({
          error: 'invalid_clips',
          message: 'Some clip assets are missing or not ready',
          missingIds: missing,
        });
      }

      // Preserve the requested order
      const orderedClips = clipAssetIds.map((id) => clips.find((c) => c.id === id));

      // Credit cost
      const cost = 3 + (enableCaptions ? 1 : 0);
      const account = await fastify.db('credit_accounts').first();
      if (!account || account.balance < cost) {
        return reply.code(402).send({
          error: 'insufficient_credits',
          message: 'Not enough credits for assembly',
          required: cost,
          available: account?.balance ?? 0,
        });
      }

      // Create output asset record
      const assetId = randomUUID();
      await fastify.db('assets').insert({
        id: assetId,
        project_id: projectId,
        type: 'video',
        prompt: `[assembly] ${clipAssetIds.length} clips`,
        provider: 'creatomate',
        quality_tier: 'standard',
        status: 'pending',
        credit_cost: cost,
        created_at: new Date(),
      });

      // Dispatch assembly job
      const jobId = randomUUID();
      await fastify.generationQueue.add('assemble', {
        jobId,
        assetId,
        projectId,
        clipAssetIds,
        clips: orderedClips.map((c) => ({
          filePath: c.file_path,
          duration: c.duration_seconds || null,
        })),
        aspectRatio: aspectRatio || '16:9',
        enableCaptions: enableCaptions || false,
        transition: transition || 'none',
      }, {
        jobId,
        attempts: 2,
        backoff: { type: 'exponential', delay: 10000 },
      });

      return reply.code(202).send({ jobId, assetId, status: 'queued' });
    },
  });
}
