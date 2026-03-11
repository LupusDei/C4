import { randomUUID } from 'node:crypto';
import { getCreditCost } from '../config/credit-costs.js';
import { captionsFromScript } from '../services/captions.js';
import { splitScript, perturbPrompt } from '../services/scene-splitter.js';

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

// --- Backend-2 schema definitions ---

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

      // Find the scene to get its storyboard_id before deleting
      const scene = await fastify.db('scenes').where({ id }).first();
      if (!scene) {
        return reply.code(404).send({ error: 'not_found', message: 'Scene not found' });
      }

      await fastify.db('scenes').where({ id }).del();

      // Renumber remaining scenes to close order_index gaps
      const remaining = await fastify.db('scenes')
        .where({ storyboard_id: scene.storyboard_id })
        .orderBy('order_index', 'asc');

      for (let i = 0; i < remaining.length; i++) {
        if (remaining[i].order_index !== i) {
          await fastify.db('scenes')
            .where({ id: remaining[i].id })
            .update({ order_index: i, updated_at: fastify.db.fn.now() });
        }
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

      // Validate minimum script length
      const wordCount = script_text.trim().split(/\s+/).filter(w => w.length > 0).length;
      if (wordCount < 10) {
        return reply.code(400).send({
          error: 'script_too_short',
          message: 'Script too short — minimum 10 words required',
        });
      }

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

      // Delete existing scenes and insert new ones in a transaction
      const { scenes, updatedStoryboard } = await fastify.db.transaction(async (trx) => {
        await trx('scenes').where({ storyboard_id: id }).del();

        const sceneRecords = sceneData.map((scene, index) => ({
          storyboard_id: id,
          order_index: index,
          narration_text: scene.narration_text || '',
          visual_prompt: scene.visual_prompt || '',
          duration_seconds: scene.duration_seconds ?? 5.0,
        }));

        const insertedScenes = await trx('scenes')
          .insert(sceneRecords)
          .returning('*');

        const [storyboardResult] = await trx('storyboards')
          .where({ id })
          .update({ status: 'complete', updated_at: trx.fn.now() })
          .returning('*');

        return { scenes: insertedScenes, updatedStoryboard: storyboardResult };
      });

      // Sort scenes by order_index since returning('*') may not preserve order
      scenes.sort((a, b) => a.order_index - b.order_index);

      return { storyboard: updatedStoryboard, scenes };
    },
  });

  // =====================
  // Batch Generation (Phase 5.1)
  // =====================

  // --- Batch-generate assets for all scenes ---
  fastify.post('/api/storyboards/:id/generate', {
    schema: {
      description: 'Batch-generate assets for all scenes in a storyboard that lack an asset',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
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
        .orderBy('order_index', 'asc');

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

  // --- Estimate generation cost ---
  fastify.get('/api/storyboards/:id/generate/estimate', {
    schema: {
      description: 'Estimate credit cost for batch-generating assets',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      querystring: {
        type: 'object',
        properties: {
          type: { type: 'string', enum: ['image', 'video'], default: 'image' },
          provider: { type: 'string' },
          quality: { type: 'string', enum: ['budget', 'standard', 'premium'], default: 'standard' },
        },
      },
      response: {
        200: {
          type: 'object',
          properties: {
            scenesCount: { type: 'integer' },
            costPerScene: { type: 'integer' },
            totalCost: { type: 'integer' },
          },
        },
      },
    },
    handler: async (request, reply) => {
      const { id: storyboardId } = request.params;
      const { type = 'image', provider, quality = 'standard' } = request.query;

      const storyboard = await fastify.db('storyboards').where({ id: storyboardId }).first();
      if (!storyboard) {
        return reply.code(404).send({ error: 'not_found', message: 'Storyboard not found' });
      }

      const scenes = await fastify.db('scenes')
        .where({ storyboard_id: storyboardId })
        .whereNull('asset_id');

      const scenesCount = scenes.length;
      const costPerScene = getCreditCost(type, provider, quality);
      const totalCost = costPerScene * scenesCount;

      return { scenesCount, costPerScene, totalCost };
    },
  });

  // =====================
  // Assembly (Phase 6.1)
  // =====================

  // --- Assemble storyboard into final video ---
  fastify.post('/api/storyboards/:id/assemble', {
    schema: {
      description: 'Assemble all scenes of a storyboard into a final video with script-based captions',
      tags: ['storyboards'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
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
        .orderBy('order_index', 'asc');

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

  // =====================
  // Variations (Phase 7.1)
  // =====================

  // --- Generate prompt variations for a scene ---
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
