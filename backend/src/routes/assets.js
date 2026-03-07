import { createReadStream } from 'node:fs';
import { access } from 'node:fs/promises';
import { extname } from 'node:path';

const uuidFormat = { type: 'string', format: 'uuid' };

const assetSchema = {
  type: 'object',
  properties: {
    id: uuidFormat,
    project_id: uuidFormat,
    type: { type: 'string', enum: ['image', 'video'] },
    prompt: { type: ['string', 'null'] },
    provider: { type: ['string', 'null'] },
    quality_tier: { type: ['string', 'null'] },
    file_path: { type: ['string', 'null'] },
    thumbnail_path: { type: ['string', 'null'] },
    credit_cost: { type: 'integer' },
    status: { type: 'string', enum: ['pending', 'processing', 'complete', 'failed'] },
    metadata: { type: 'object' },
    created_at: { type: 'string', format: 'date-time' },
  },
};

const assetListSchema = {
  type: 'object',
  properties: {
    data: { type: 'array', items: assetSchema },
    total: { type: 'integer' },
    limit: { type: 'integer' },
    offset: { type: 'integer' },
  },
};

const MIME_TYPES = {
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
  '.webm': 'video/webm',
};

export default async function assetRoutes(fastify) {
  // --- List assets for a project ---
  fastify.get('/api/projects/:projectId/assets', {
    schema: {
      description: 'List assets for a project with pagination',
      tags: ['assets'],
      params: {
        type: 'object',
        required: ['projectId'],
        properties: { projectId: uuidFormat },
      },
      querystring: {
        type: 'object',
        properties: {
          limit: { type: 'integer', minimum: 1, maximum: 100, default: 50 },
          offset: { type: 'integer', minimum: 0, default: 0 },
        },
      },
      response: { 200: assetListSchema },
    },
    handler: async (request) => {
      const { projectId } = request.params;
      const { limit, offset } = request.query;

      const [assets, [{ count }]] = await Promise.all([
        fastify.db('assets')
          .where({ project_id: projectId })
          .orderBy('created_at', 'desc')
          .limit(limit)
          .offset(offset),
        fastify.db('assets')
          .where({ project_id: projectId })
          .count('* as count'),
      ]);

      return {
        data: assets,
        total: parseInt(count, 10),
        limit,
        offset,
      };
    },
  });

  // --- Get single asset ---
  fastify.get('/api/assets/:id', {
    schema: {
      description: 'Get a single asset by ID',
      tags: ['assets'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      response: { 200: assetSchema },
    },
    handler: async (request, reply) => {
      const asset = await fastify.db('assets').where({ id: request.params.id }).first();
      if (!asset) {
        return reply.code(404).send({ error: 'not_found', message: 'Asset not found' });
      }
      return asset;
    },
  });

  // --- Delete asset ---
  fastify.delete('/api/assets/:id', {
    schema: {
      description: 'Delete an asset and its files',
      tags: ['assets'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      response: {
        200: {
          type: 'object',
          properties: { message: { type: 'string' } },
        },
      },
    },
    handler: async (request, reply) => {
      const asset = await fastify.db('assets').where({ id: request.params.id }).first();
      if (!asset) {
        return reply.code(404).send({ error: 'not_found', message: 'Asset not found' });
      }

      if (asset.file_path) await fastify.storage.deleteFile(asset.file_path);
      if (asset.thumbnail_path) await fastify.storage.deleteFile(asset.thumbnail_path);

      await fastify.db('assets').where({ id: request.params.id }).del();
      return { message: 'Asset deleted' };
    },
  });

  // --- Serve asset file ---
  fastify.get('/api/assets/:id/file', {
    schema: {
      description: 'Serve the asset file (image or video)',
      tags: ['assets'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
    },
    handler: async (request, reply) => {
      const asset = await fastify.db('assets').where({ id: request.params.id }).first();
      if (!asset) {
        return reply.code(404).send({ error: 'not_found', message: 'Asset not found' });
      }
      if (!asset.file_path) {
        return reply.code(404).send({ error: 'not_found', message: 'Asset file not available' });
      }

      try {
        await access(asset.file_path);
      } catch {
        return reply.code(404).send({ error: 'not_found', message: 'File not found on disk' });
      }

      const ext = extname(asset.file_path).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';

      return reply
        .type(contentType)
        .send(createReadStream(asset.file_path));
    },
  });

  // --- Serve asset thumbnail ---
  fastify.get('/api/assets/:id/thumbnail', {
    schema: {
      description: 'Serve the asset thumbnail',
      tags: ['assets'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
    },
    handler: async (request, reply) => {
      const asset = await fastify.db('assets').where({ id: request.params.id }).first();
      if (!asset) {
        return reply.code(404).send({ error: 'not_found', message: 'Asset not found' });
      }
      if (!asset.thumbnail_path) {
        return reply.code(404).send({ error: 'not_found', message: 'Thumbnail not available' });
      }

      try {
        await access(asset.thumbnail_path);
      } catch {
        return reply.code(404).send({ error: 'not_found', message: 'Thumbnail not found on disk' });
      }

      const ext = extname(asset.thumbnail_path).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'image/png';

      return reply
        .type(contentType)
        .send(createReadStream(asset.thumbnail_path));
    },
  });
}
