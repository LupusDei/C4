import { randomUUID } from 'node:crypto';
import { getCreditCost } from '../config/credit-costs.js';
import { captionsFromScript } from '../services/captions.js';
import { perturbPrompt } from '../services/scene-splitter.js';

// --- Schema definitions ---

const generateBodySchema = {
  type: 'object',
  required: ['type'],
  properties: {
    type: { type: 'string', enum: ['image', 'video'] },
    provider: { type: 'string' },
    quality: { type: 'string', enum: ['budget', 'standard', 'premium'], default: 'standard' },
  },
};

const generateResponseSchema = {
  type: 'object',
  properties: {
    jobs: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          sceneId: { type: 'string', format: 'uuid' },
          jobId: { type: 'string', format: 'uuid' },
        },
      },
    },
    totalCost: { type: 'integer' },
  },
};

const assembleBodySchema = {
  type: 'object',
  properties: {
    transition: { type: 'string', enum: ['none', 'crossfade', 'fade'], default: 'none' },
    captions: { type: 'boolean', default: true },
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

const variationsParamsSchema = {
  type: 'object',
  required: ['id', 'sceneId'],
  properties: {
    id: { type: 'string', format: 'uuid' },
    sceneId: { type: 'string', format: 'uuid' },
  },
};

const variationsBodySchema = {
  type: 'object',
  required: ['count', 'type'],
  properties: {
    count: { type: 'integer', enum: [2, 3], default: 2 },
    type: { type: 'string', enum: ['image', 'video'] },
    provider: { type: 'string' },
    quality: { type: 'string', enum: ['budget', 'standard', 'premium'], default: 'standard' },
  },
};

const variationsResponseSchema = {
  type: 'object',
  properties: {
    jobs: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          variationIndex: { type: 'integer' },
          jobId: { type: 'string', format: 'uuid' },
          prompt: { type: 'string' },
        },
      },
    },
  },
};

export default async function storyboardRoutes(fastify) {

  // -------------------------------------------------------
  // Phase 5.1: POST /api/storyboards/:id/generate
  // -------------------------------------------------------
  fastify.post('/api/storyboards/:id/generate', {
    schema: {
      description: 'Batch-generate assets for all scenes in a storyboard that lack an asset',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: { type: 'string', format: 'uuid' } },
      },
      body: generateBodySchema,
      response: { 202: generateResponseSchema },
    },
    handler: async (request, reply) => {
      const { id: storyboardId } = request.params;
      const { type, provider, quality } = request.body;
      const qualityTier = quality || 'standard';

      // Verify storyboard exists
      const storyboard = await fastify.db('storyboards').where({ id: storyboardId }).first();
      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      // Fetch scenes without an asset
      const scenes = await fastify.db('scenes')
        .where({ storyboard_id: storyboardId })
        .whereNull('asset_id')
        .orderBy('scene_number', 'asc');

      if (scenes.length === 0) {
        return reply.code(400).send({
          error: 'no_scenes',
          message: 'All scenes already have assets generated',
        });
      }

      // Calculate total cost
      const costPerScene = getCreditCost(type, provider, qualityTier);
      const totalCost = costPerScene * scenes.length;

      // Check credit balance
      const account = await fastify.db('credit_accounts').first();
      if (!account || account.balance < totalCost) {
        const available = account?.balance ?? 0;
        const affordable = Math.floor(available / costPerScene);
        return reply.code(402).send({
          error: 'insufficient_credits',
          message: `Not enough credits. Need ${totalCost} for ${scenes.length} scenes, have ${available}. Can afford ${affordable} scenes.`,
          required: totalCost,
          available,
          scenesRequested: scenes.length,
          scenesAffordable: affordable,
        });
      }

      // Queue a generation job for each scene
      const jobs = [];
      for (const scene of scenes) {
        const assetId = randomUUID();
        await fastify.db('assets').insert({
          id: assetId,
          project_id: storyboard.project_id,
          type,
          prompt: scene.visual_prompt,
          provider: provider || null,
          quality_tier: qualityTier,
          status: 'pending',
          credit_cost: costPerScene,
          created_at: new Date(),
        });

        const jobId = randomUUID();
        const jobType = type === 'image' ? 'generate-image' : 'generate-video';
        await fastify.generationQueue.add(jobType, {
          jobId,
          assetId,
          projectId: storyboard.project_id,
          prompt: scene.visual_prompt,
          provider,
          qualityTier,
          storyboardId,
          sceneId: scene.id,
        }, {
          jobId,
          attempts: 2,
          backoff: { type: 'exponential', delay: 5000 },
        });

        jobs.push({ sceneId: scene.id, jobId });
      }

      // Update storyboard status
      await fastify.db('storyboards').where({ id: storyboardId }).update({
        status: 'generating',
        updated_at: new Date(),
      });

      return reply.code(202).send({ jobs, totalCost });
    },
  });

  // -------------------------------------------------------
  // Phase 6.1: POST /api/storyboards/:id/assemble
  // -------------------------------------------------------
  fastify.post('/api/storyboards/:id/assemble', {
    schema: {
      description: 'Assemble all scenes of a storyboard into a final video with script-based captions',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: { type: 'string', format: 'uuid' } },
      },
      body: assembleBodySchema,
      response: { 202: assembleResponseSchema },
    },
    handler: async (request, reply) => {
      const { id: storyboardId } = request.params;
      const { transition, captions } = request.body;
      const enableCaptions = captions !== false; // default true

      // Verify storyboard exists
      const storyboard = await fastify.db('storyboards').where({ id: storyboardId }).first();
      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      // Gather all scenes in order
      const scenes = await fastify.db('scenes')
        .where({ storyboard_id: storyboardId })
        .orderBy('scene_number', 'asc');

      if (scenes.length === 0) {
        return reply.code(400).send({
          error: 'no_scenes',
          message: 'Storyboard has no scenes',
        });
      }

      // Verify all scenes have assets
      const missingAssets = scenes.filter((s) => !s.asset_id);
      if (missingAssets.length > 0) {
        return reply.code(400).send({
          error: 'incomplete_scenes',
          message: `${missingAssets.length} scene(s) do not have generated assets yet`,
          missingSceneIds: missingAssets.map((s) => s.id),
        });
      }

      // Fetch scene assets to build clip list
      const assetIds = scenes.map((s) => s.asset_id);
      const assets = await fastify.db('assets').whereIn('id', assetIds);
      const assetMap = new Map(assets.map((a) => [a.id, a]));

      const clips = scenes.map((scene) => {
        const asset = assetMap.get(scene.asset_id);
        return {
          filePath: asset.file_path,
          duration: scene.duration_seconds || null,
        };
      });

      // Generate captions from script data
      let srtContent = null;
      if (enableCaptions) {
        srtContent = captionsFromScript(
          scenes.map((s) => ({
            narration_text: s.narration_text,
            duration_seconds: s.duration_seconds || 5,
          })),
        );
        // If no narration text produced captions, set to null
        if (!srtContent || srtContent.trim() === '') {
          srtContent = null;
        }
      }

      // Credit cost: assembly + optional captioning
      const cost = getCreditCost('assembly') + (srtContent ? getCreditCost('captioning') : 0);
      const account = await fastify.db('credit_accounts').first();
      if (!account || account.balance < cost) {
        return reply.code(402).send({
          error: 'insufficient_credits',
          message: 'Not enough credits for assembly',
          required: cost,
          available: account?.balance ?? 0,
        });
      }

      // Create output asset
      const assetId = randomUUID();
      await fastify.db('assets').insert({
        id: assetId,
        project_id: storyboard.project_id,
        type: 'video',
        prompt: `[storyboard-assembly] ${storyboard.title} (${scenes.length} scenes)`,
        provider: 'creatomate',
        quality_tier: 'standard',
        status: 'pending',
        credit_cost: cost,
        created_at: new Date(),
      });

      // Queue assembly job
      const jobId = randomUUID();
      await fastify.generationQueue.add('assemble', {
        jobId,
        assetId,
        projectId: storyboard.project_id,
        clips,
        aspectRatio: '16:9',
        enableCaptions: false, // We pass SRT directly, don't transcribe
        transition: transition || 'none',
        srtContent, // Pass pre-generated SRT to assembly handler
        storyboardId,
      }, {
        jobId,
        attempts: 2,
        backoff: { type: 'exponential', delay: 10000 },
      });

      return reply.code(202).send({ jobId, assetId, status: 'queued' });
    },
  });

  // -------------------------------------------------------
  // Phase 7.1: POST /api/storyboards/:id/scenes/:sceneId/variations
  // -------------------------------------------------------
  fastify.post('/api/storyboards/:id/scenes/:sceneId/variations', {
    schema: {
      description: 'Generate visual prompt variations for a storyboard scene',
      tags: ['storyboards'],
      params: variationsParamsSchema,
      body: variationsBodySchema,
      response: { 202: variationsResponseSchema },
    },
    handler: async (request, reply) => {
      const { id: storyboardId, sceneId } = request.params;
      const { count, type, provider, quality } = request.body;
      const qualityTier = quality || 'standard';

      // Verify storyboard and scene exist
      const storyboard = await fastify.db('storyboards').where({ id: storyboardId }).first();
      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      const scene = await fastify.db('scenes')
        .where({ id: sceneId, storyboard_id: storyboardId })
        .first();
      if (!scene) {
        return reply.code(404).send({ error: 'not_found', message: 'Scene not found in this storyboard' });
      }

      // Calculate total cost for all variations
      const costPerVariation = getCreditCost(type, provider, qualityTier);
      const totalCost = costPerVariation * count;

      // Check credits
      const account = await fastify.db('credit_accounts').first();
      if (!account || account.balance < totalCost) {
        return reply.code(402).send({
          error: 'insufficient_credits',
          message: `Not enough credits for ${count} variations`,
          required: totalCost,
          available: account?.balance ?? 0,
        });
      }

      // Generate prompt variations using LLM
      const promptVariations = await perturbPrompt(scene.visual_prompt, count);
      if (promptVariations.length === 0) {
        return reply.code(500).send({
          error: 'perturbation_failed',
          message: 'Failed to generate prompt variations',
        });
      }

      // Queue generation jobs for each variation
      const jobs = [];
      for (let i = 0; i < promptVariations.length; i++) {
        const prompt = promptVariations[i];
        const assetId = randomUUID();

        await fastify.db('assets').insert({
          id: assetId,
          project_id: storyboard.project_id,
          type,
          prompt,
          provider: provider || null,
          quality_tier: qualityTier,
          status: 'pending',
          credit_cost: costPerVariation,
          created_at: new Date(),
        });

        const jobId = randomUUID();
        const jobType = type === 'image' ? 'generate-image' : 'generate-video';
        await fastify.generationQueue.add(jobType, {
          jobId,
          assetId,
          projectId: storyboard.project_id,
          prompt,
          provider,
          qualityTier,
          storyboardId,
          sceneId,
          variationIndex: i,
        }, {
          jobId,
          attempts: 2,
          backoff: { type: 'exponential', delay: 5000 },
        });

        jobs.push({ variationIndex: i, jobId, prompt });
      }

      return reply.code(202).send({ jobs });
    },
  });
}
