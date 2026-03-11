import { splitScript } from '../services/scene-splitter.js';

const uuidFormat = { type: 'string', format: 'uuid' };

const sceneSchema = {
  type: 'object',
  properties: {
    id: uuidFormat,
    storyboard_id: uuidFormat,
    order_index: { type: 'integer' },
    narration_text: { type: 'string' },
    visual_prompt: { type: 'string' },
    duration_seconds: { type: 'number' },
    asset_id: { type: ['string', 'null'], format: 'uuid' },
    variations: { type: 'array' },
    created_at: { type: 'string', format: 'date-time' },
    updated_at: { type: 'string', format: 'date-time' },
  },
};

const storyboardSchema = {
  type: 'object',
  properties: {
    id: uuidFormat,
    project_id: uuidFormat,
    title: { type: 'string' },
    script_text: { type: ['string', 'null'] },
    status: { type: 'string' },
    created_at: { type: 'string', format: 'date-time' },
    updated_at: { type: 'string', format: 'date-time' },
  },
};

const storyboardWithScenesSchema = {
  type: 'object',
  properties: {
    ...storyboardSchema.properties,
    scenes: { type: 'array', items: sceneSchema },
  },
};

const storyboardListSchema = {
  type: 'array',
  items: storyboardSchema,
};

const sceneListSchema = {
  type: 'array',
  items: sceneSchema,
};

export default async function storyboardRoutes(fastify) {
  // =====================
  // Storyboard CRUD
  // =====================

  // --- Create storyboard ---
  fastify.post('/api/projects/:projectId/storyboards', {
    schema: {
      description: 'Create a new storyboard for a project',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['projectId'],
        properties: { projectId: uuidFormat },
      },
      body: {
        type: 'object',
        required: ['title'],
        properties: {
          title: { type: 'string', minLength: 1, maxLength: 255 },
        },
      },
      response: { 201: storyboardSchema },
    },
    handler: async (request, reply) => {
      const { projectId } = request.params;
      const { title } = request.body;

      const project = await fastify.db('projects').where({ id: projectId }).first();
      if (!project) {
        return reply.code(404).send({ error: 'not_found', message: 'Project not found' });
      }

      const [storyboard] = await fastify.db('storyboards')
        .insert({ project_id: projectId, title })
        .returning('*');

      return reply.code(201).send(storyboard);
    },
  });

  // --- List storyboards for project ---
  fastify.get('/api/projects/:projectId/storyboards', {
    schema: {
      description: 'List all storyboards for a project',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['projectId'],
        properties: { projectId: uuidFormat },
      },
      response: { 200: storyboardListSchema },
    },
    handler: async (request) => {
      const { projectId } = request.params;

      const storyboards = await fastify.db('storyboards')
        .where({ project_id: projectId })
        .orderBy('created_at', 'desc');

      return storyboards;
    },
  });

  // --- Get single storyboard with scenes ---
  fastify.get('/api/storyboards/:id', {
    schema: {
      description: 'Get a single storyboard with its scenes',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      response: { 200: storyboardWithScenesSchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;

      const storyboard = await fastify.db('storyboards').where({ id }).first();
      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      const scenes = await fastify.db('scenes')
        .where({ storyboard_id: id })
        .orderBy('order_index', 'asc');

      return { ...storyboard, scenes };
    },
  });

  // --- Update storyboard ---
  fastify.put('/api/storyboards/:id', {
    schema: {
      description: 'Update a storyboard',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      body: {
        type: 'object',
        properties: {
          title: { type: 'string', minLength: 1, maxLength: 255 },
          status: { type: 'string', enum: ['draft', 'generating', 'complete', 'assembled'] },
        },
      },
      response: { 200: storyboardSchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const updates = { ...request.body, updated_at: fastify.db.fn.now() };

      const [storyboard] = await fastify.db('storyboards')
        .where({ id })
        .update(updates)
        .returning('*');

      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      return storyboard;
    },
  });

  // --- Delete storyboard ---
  fastify.delete('/api/storyboards/:id', {
    schema: {
      description: 'Delete a storyboard and all its scenes',
      tags: ['storyboards'],
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
      const { id } = request.params;

      const deleted = await fastify.db('storyboards').where({ id }).del();
      if (!deleted) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      return { message: 'Storyboard deleted' };
    },
  });

  // =====================
  // Scene CRUD
  // =====================

  // --- Create scene ---
  fastify.post('/api/storyboards/:storyboardId/scenes', {
    schema: {
      description: 'Create a new scene in a storyboard',
      tags: ['scenes'],
      params: {
        type: 'object',
        required: ['storyboardId'],
        properties: { storyboardId: uuidFormat },
      },
      body: {
        type: 'object',
        properties: {
          narration_text: { type: 'string', default: '' },
          visual_prompt: { type: 'string', default: '' },
          duration_seconds: { type: 'number', minimum: 0, default: 5.0 },
          asset_id: { type: ['string', 'null'], format: 'uuid' },
        },
      },
      response: { 201: sceneSchema },
    },
    handler: async (request, reply) => {
      const { storyboardId } = request.params;
      const { narration_text, visual_prompt, duration_seconds, asset_id } = request.body;

      const storyboard = await fastify.db('storyboards').where({ id: storyboardId }).first();
      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      // Determine next order_index
      const [{ max_index }] = await fastify.db('scenes')
        .where({ storyboard_id: storyboardId })
        .max('order_index as max_index');

      const order_index = (max_index ?? -1) + 1;

      const [scene] = await fastify.db('scenes')
        .insert({
          storyboard_id: storyboardId,
          order_index,
          narration_text: narration_text || '',
          visual_prompt: visual_prompt || '',
          duration_seconds: duration_seconds ?? 5.0,
          asset_id: asset_id || null,
        })
        .returning('*');

      return reply.code(201).send(scene);
    },
  });

  // --- List scenes for storyboard ---
  fastify.get('/api/storyboards/:storyboardId/scenes', {
    schema: {
      description: 'List all scenes for a storyboard, ordered by order_index',
      tags: ['scenes'],
      params: {
        type: 'object',
        required: ['storyboardId'],
        properties: { storyboardId: uuidFormat },
      },
      response: { 200: sceneListSchema },
    },
    handler: async (request) => {
      const { storyboardId } = request.params;

      const scenes = await fastify.db('scenes')
        .where({ storyboard_id: storyboardId })
        .orderBy('order_index', 'asc');

      return scenes;
    },
  });

  // --- Update scene ---
  fastify.put('/api/scenes/:id', {
    schema: {
      description: 'Update a scene',
      tags: ['scenes'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      body: {
        type: 'object',
        properties: {
          narration_text: { type: 'string' },
          visual_prompt: { type: 'string' },
          duration_seconds: { type: 'number', minimum: 0 },
          asset_id: { type: ['string', 'null'], format: 'uuid' },
        },
      },
      response: { 200: sceneSchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const updates = { ...request.body, updated_at: fastify.db.fn.now() };

      const [scene] = await fastify.db('scenes')
        .where({ id })
        .update(updates)
        .returning('*');

      if (!scene) {
        return reply.code(404).send({ error: 'not_found', message: 'Scene not found' });
      }

      return scene;
    },
  });

  // --- Delete scene ---
  fastify.delete('/api/scenes/:id', {
    schema: {
      description: 'Delete a scene',
      tags: ['scenes'],
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
      const { id } = request.params;

      const deleted = await fastify.db('scenes').where({ id }).del();
      if (!deleted) {
        return reply.code(404).send({ error: 'not_found', message: 'Scene not found' });
      }

      return { message: 'Scene deleted' };
    },
  });

  // --- Reorder scenes ---
  fastify.patch('/api/storyboards/:storyboardId/scenes/reorder', {
    schema: {
      description: 'Reorder scenes in a storyboard',
      tags: ['scenes'],
      params: {
        type: 'object',
        required: ['storyboardId'],
        properties: { storyboardId: uuidFormat },
      },
      body: {
        type: 'object',
        required: ['order'],
        properties: {
          order: {
            type: 'array',
            items: uuidFormat,
            minItems: 1,
          },
        },
      },
      response: { 200: sceneListSchema },
    },
    handler: async (request, reply) => {
      const { storyboardId } = request.params;
      const { order } = request.body;

      const storyboard = await fastify.db('storyboards').where({ id: storyboardId }).first();
      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      // Update order_index for each scene in a transaction
      await fastify.db.transaction(async (trx) => {
        for (let i = 0; i < order.length; i++) {
          await trx('scenes')
            .where({ id: order[i], storyboard_id: storyboardId })
            .update({ order_index: i, updated_at: trx.fn.now() });
        }
      });

      const scenes = await fastify.db('scenes')
        .where({ storyboard_id: storyboardId })
        .orderBy('order_index', 'asc');

      return scenes;
    },
  });

  // =====================
  // Scene Splitting (US1)
  // =====================

  // --- Split script into scenes ---
  fastify.post('/api/storyboards/:id/split', {
    schema: {
      description: 'Split a script into scenes using AI',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      body: {
        type: 'object',
        required: ['script_text'],
        properties: {
          script_text: { type: 'string', minLength: 1, maxLength: 50000 },
        },
      },
      response: {
        200: {
          type: 'object',
          properties: {
            storyboard: storyboardSchema,
            scenes: sceneListSchema,
          },
        },
      },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const { script_text } = request.body;

      const storyboard = await fastify.db('storyboards').where({ id }).first();
      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      // Update storyboard with script text and set status to generating
      await fastify.db('storyboards')
        .where({ id })
        .update({
          script_text,
          status: 'generating',
          updated_at: fastify.db.fn.now(),
        });

      let sceneData;
      try {
        sceneData = await splitScript(script_text);
      } catch (err) {
        // Revert status on failure
        await fastify.db('storyboards')
          .where({ id })
          .update({ status: 'draft', updated_at: fastify.db.fn.now() });

        return reply.code(500).send({
          error: 'split_failed',
          message: err.message || 'Failed to split script into scenes',
        });
      }

      // Delete existing scenes for this storyboard before inserting new ones
      await fastify.db('scenes').where({ storyboard_id: id }).del();

      // Insert new scenes
      const sceneRecords = sceneData.map((scene, index) => ({
        storyboard_id: id,
        order_index: index,
        narration_text: scene.narration_text || '',
        visual_prompt: scene.visual_prompt || '',
        duration_seconds: scene.duration_seconds ?? 5.0,
      }));

      const scenes = await fastify.db('scenes')
        .insert(sceneRecords)
        .returning('*');

      // Update storyboard status to complete
      const [updatedStoryboard] = await fastify.db('storyboards')
        .where({ id })
        .update({ status: 'complete', updated_at: fastify.db.fn.now() })
        .returning('*');

      // Sort scenes by order_index since returning('*') may not preserve order
      scenes.sort((a, b) => a.order_index - b.order_index);

      return { storyboard: updatedStoryboard, scenes };
    },
  });
}
