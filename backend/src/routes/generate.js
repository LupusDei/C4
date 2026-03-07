import { randomUUID } from 'node:crypto';
import { providers as imageProviders, qualityTiers as imageQualityTiers } from '../services/ai-image.js';
import { providers as videoProviders, qualityTiers as videoQualityTiers } from '../services/ai-video.js';
import { MAX_SEGMENT_DURATION } from '../services/video-extend.js';
import { getCreditCost } from '../config/credit-costs.js';

// --- Shared response schema ---

const jobResponseSchema = {
  type: 'object',
  properties: {
    jobId: { type: 'string', format: 'uuid' },
    assetId: { type: 'string', format: 'uuid' },
    status: { type: 'string' },
  },
};

// --- Image generation ---

const imageBodySchema = {
  type: 'object',
  required: ['prompt', 'projectId'],
  properties: {
    prompt: { type: 'string', minLength: 1, maxLength: 4000 },
    projectId: { type: 'string', format: 'uuid' },
    provider: { type: 'string', enum: imageProviders },
    qualityTier: { type: 'string', enum: imageQualityTiers, default: 'standard' },
    aspectRatio: { type: 'string', pattern: '^\\d+:\\d+$', default: '1:1' },
  },
};

// --- Video generation ---

const videoBodySchema = {
  type: 'object',
  required: ['prompt', 'projectId'],
  properties: {
    prompt: { type: 'string', minLength: 1, maxLength: 4000 },
    projectId: { type: 'string', format: 'uuid' },
    provider: { type: 'string', enum: videoProviders },
    qualityTier: { type: 'string', enum: videoQualityTiers, default: 'standard' },
    duration: { type: 'integer', minimum: 1, maximum: 15, default: 5 },
    aspectRatio: { type: 'string', pattern: '^\\d+:\\d+$', default: '16:9' },
    resolution: { type: 'string', enum: ['480p', '720p'], default: '720p' },
    mode: { type: 'string', enum: ['text-to-video', 'image-to-video'], default: 'text-to-video' },
    sourceAssetId: { type: 'string', format: 'uuid' },
  },
};

// --- Video extension ---

const extendBodySchema = {
  type: 'object',
  required: ['assetId', 'prompt'],
  properties: {
    assetId: { type: 'string', format: 'uuid' },
    prompt: { type: 'string', minLength: 1, maxLength: 4000 },
    maxDuration: { type: 'integer', minimum: 1, maximum: 30, default: 15 },
  },
};

export default async function generateRoutes(fastify) {

  // POST /api/generate/image
  fastify.post('/api/generate/image', {
    schema: {
      description: 'Generate an AI image from a text prompt',
      tags: ['generation'],
      body: imageBodySchema,
      response: { 202: jobResponseSchema },
    },
    handler: async (request, reply) => {
      const { prompt, projectId, provider, qualityTier, aspectRatio } = request.body;

      const cost = getCreditCost('image', provider, qualityTier || 'standard');
      const account = await fastify.db('credit_accounts').first();
      if (!account || account.balance < cost) {
        return reply.code(402).send({
          error: 'insufficient_credits',
          message: 'Not enough credits for this generation',
          required: cost,
          available: account?.balance ?? 0,
        });
      }

      const assetId = randomUUID();
      await fastify.db('assets').insert({
        id: assetId,
        project_id: projectId,
        type: 'image',
        prompt,
        provider: provider || null,
        quality_tier: qualityTier || 'standard',
        status: 'pending',
        credit_cost: cost,
        created_at: new Date(),
      });

      const jobId = randomUUID();
      await fastify.generationQueue.add('generate-image', {
        jobId,
        assetId,
        projectId,
        prompt,
        provider,
        qualityTier: qualityTier || 'standard',
        aspectRatio: aspectRatio || '1:1',
      }, {
        jobId,
        attempts: 2,
        backoff: { type: 'exponential', delay: 5000 },
      });

      return reply.code(202).send({ jobId, assetId, status: 'queued' });
    },
  });

  // POST /api/generate/video
  fastify.post('/api/generate/video', {
    schema: {
      description: 'Generate an AI video from a text prompt or image',
      tags: ['generation'],
      body: videoBodySchema,
      response: { 202: jobResponseSchema },
    },
    handler: async (request, reply) => {
      const { prompt, projectId, provider, qualityTier, duration, aspectRatio, resolution, mode, sourceAssetId } = request.body;

      // Resolve image URL for image-to-video mode
      let imageUrl = null;
      if (mode === 'image-to-video') {
        if (!sourceAssetId) {
          return reply.code(400).send({
            error: 'missing_source_asset',
            message: 'sourceAssetId is required for image-to-video mode',
          });
        }
        const source = await fastify.db('assets').where({ id: sourceAssetId, type: 'image', status: 'complete' }).first();
        if (!source) {
          return reply.code(404).send({ error: 'source_not_found', message: 'Source image asset not found or not ready' });
        }
        imageUrl = source.file_path;
      }

      const cost = getCreditCost('video', provider, qualityTier || 'standard');
      const account = await fastify.db('credit_accounts').first();
      if (!account || account.balance < cost) {
        return reply.code(402).send({
          error: 'insufficient_credits',
          message: 'Not enough credits for this generation',
          required: cost,
          available: account?.balance ?? 0,
        });
      }

      const assetId = randomUUID();
      await fastify.db('assets').insert({
        id: assetId,
        project_id: projectId,
        type: 'video',
        prompt,
        provider: provider || null,
        quality_tier: qualityTier || 'standard',
        status: 'pending',
        credit_cost: cost,
        created_at: new Date(),
      });

      const jobId = randomUUID();
      await fastify.generationQueue.add('generate-video', {
        jobId,
        assetId,
        projectId,
        prompt,
        provider,
        qualityTier: qualityTier || 'standard',
        duration: duration || 5,
        aspectRatio: aspectRatio || '16:9',
        resolution: resolution || '720p',
        imageUrl,
      }, {
        jobId,
        attempts: 2,
        backoff: { type: 'exponential', delay: 10000 },
      });

      return reply.code(202).send({ jobId, assetId, status: 'queued' });
    },
  });

  // POST /api/generate/video/extend
  fastify.post('/api/generate/video/extend', {
    schema: {
      description: 'Extend an existing video using Grok Imagine continuation',
      tags: ['generation'],
      body: extendBodySchema,
      response: { 202: jobResponseSchema },
    },
    handler: async (request, reply) => {
      const { assetId: sourceAssetId, prompt, maxDuration } = request.body;

      // Validate source asset
      const source = await fastify.db('assets').where({ id: sourceAssetId, type: 'video', status: 'complete' }).first();
      if (!source) {
        return reply.code(404).send({ error: 'source_not_found', message: 'Source video asset not found or not ready' });
      }

      // Credit cost: per second of extension
      const extensionSeconds = (maxDuration || 15) - (source.duration_seconds || 5);
      const costPerSecond = getCreditCost('video_extension');
      const cost = Math.max(Math.ceil(extensionSeconds * costPerSecond), 5);

      const account = await fastify.db('credit_accounts').first();
      if (!account || account.balance < cost) {
        return reply.code(402).send({
          error: 'insufficient_credits',
          message: 'Not enough credits for this extension',
          required: cost,
          available: account?.balance ?? 0,
        });
      }

      const newAssetId = randomUUID();
      await fastify.db('assets').insert({
        id: newAssetId,
        project_id: source.project_id,
        type: 'video',
        prompt: `[extend] ${prompt}`,
        provider: 'grok-imagine',
        quality_tier: 'standard',
        status: 'pending',
        credit_cost: cost,
        created_at: new Date(),
      });

      const jobId = randomUUID();
      await fastify.generationQueue.add('video-extend', {
        jobId,
        assetId: newAssetId,
        sourceAssetId,
        projectId: source.project_id,
        prompt,
        maxDuration: maxDuration || 15,
      }, {
        jobId,
        attempts: 1,
        backoff: { type: 'exponential', delay: 10000 },
      });

      return reply.code(202).send({ jobId, assetId: newAssetId, status: 'queued' });
    },
  });
}
