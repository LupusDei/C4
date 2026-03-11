import Anthropic from '@anthropic-ai/sdk';
import config from '../config.js';

const uuidFormat = { type: 'string', format: 'uuid' };

const stylePresetSchema = {
  type: 'object',
  properties: {
    id: uuidFormat,
    name: { type: 'string' },
    description: { type: ['string', 'null'] },
    prompt_modifier: { type: 'string' },
    category: { type: 'string' },
    thumbnail_url: { type: ['string', 'null'] },
    is_custom: { type: 'boolean' },
    user_id: { type: ['string', 'null'] },
    created_at: { type: 'string', format: 'date-time' },
    updated_at: { type: 'string', format: 'date-time' },
  },
};

const stylePresetListSchema = {
  type: 'array',
  items: stylePresetSchema,
};

const extractedStyleSchema = {
  type: 'object',
  properties: {
    name: { type: 'string' },
    description: { type: 'string' },
    promptModifier: { type: 'string' },
    category: { type: 'string' },
  },
};

const VALID_CATEGORIES = ['cinematic', 'photography', 'illustration', 'digital-art', 'retro', 'abstract'];

export default async function styleRoutes(fastify) {
  // --- List style presets ---
  fastify.get('/api/styles', {
    schema: {
      description: 'List all style presets (system + user custom)',
      tags: ['styles'],
      querystring: {
        type: 'object',
        properties: {
          category: { type: 'string', maxLength: 50 },
        },
      },
      response: { 200: stylePresetListSchema },
    },
    handler: async (request) => {
      const { category } = request.query;

      // Return all system presets + all custom presets (user_id filtering can be added when auth is implemented)
      let query = fastify.db('style_presets')
        .orderBy('is_custom')
        .orderBy('category')
        .orderBy('name');

      if (category) {
        query = query.andWhere('category', category);
      }

      return query;
    },
  });

  // --- Get single style preset ---
  fastify.get('/api/styles/:id', {
    schema: {
      description: 'Get a single style preset by ID',
      tags: ['styles'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      response: { 200: stylePresetSchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;

      const preset = await fastify.db('style_presets').where({ id }).first();
      if (!preset) {
        return reply.code(404).send({ error: 'not_found', message: 'Style preset not found' });
      }

      return preset;
    },
  });

  // --- Create custom style preset ---
  fastify.post('/api/styles', {
    schema: {
      description: 'Create a custom style preset',
      tags: ['styles'],
      body: {
        type: 'object',
        required: ['name', 'promptModifier', 'category'],
        properties: {
          name: { type: 'string', minLength: 1, maxLength: 100 },
          description: { type: 'string', maxLength: 2000 },
          promptModifier: { type: 'string', minLength: 1 },
          category: { type: 'string', minLength: 1, maxLength: 50 },
          thumbnailUrl: { type: 'string' },
        },
      },
      response: { 201: stylePresetSchema },
    },
    handler: async (request, reply) => {
      const { name, description, promptModifier, category, thumbnailUrl } = request.body;

      const [preset] = await fastify.db('style_presets')
        .insert({
          name,
          description: description || null,
          prompt_modifier: promptModifier,
          category,
          thumbnail_url: thumbnailUrl || null,
          is_custom: true,
        })
        .returning('*');

      return reply.code(201).send(preset);
    },
  });

  // --- Update custom style preset ---
  fastify.put('/api/styles/:id', {
    schema: {
      description: 'Update a custom style preset',
      tags: ['styles'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      body: {
        type: 'object',
        properties: {
          name: { type: 'string', minLength: 1, maxLength: 100 },
          description: { type: 'string', maxLength: 2000 },
          promptModifier: { type: 'string', minLength: 1 },
          category: { type: 'string', minLength: 1, maxLength: 50 },
          thumbnailUrl: { type: 'string' },
        },
      },
      response: { 200: stylePresetSchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;

      const existing = await fastify.db('style_presets').where({ id }).first();
      if (!existing) {
        return reply.code(404).send({ error: 'not_found', message: 'Style preset not found' });
      }
      if (!existing.is_custom) {
        return reply.code(403).send({ error: 'forbidden', message: 'Cannot modify system style presets' });
      }

      const updates = { updated_at: fastify.db.fn.now() };
      if (request.body.name !== undefined) updates.name = request.body.name;
      if (request.body.description !== undefined) updates.description = request.body.description;
      if (request.body.promptModifier !== undefined) updates.prompt_modifier = request.body.promptModifier;
      if (request.body.category !== undefined) updates.category = request.body.category;
      if (request.body.thumbnailUrl !== undefined) updates.thumbnail_url = request.body.thumbnailUrl;

      const [preset] = await fastify.db('style_presets')
        .where({ id })
        .update(updates)
        .returning('*');

      return preset;
    },
  });

  // --- Delete custom style preset ---
  fastify.delete('/api/styles/:id', {
    schema: {
      description: 'Delete a custom style preset',
      tags: ['styles'],
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

      const existing = await fastify.db('style_presets').where({ id }).first();
      if (!existing) {
        return reply.code(404).send({ error: 'not_found', message: 'Style preset not found' });
      }
      if (!existing.is_custom) {
        return reply.code(403).send({ error: 'forbidden', message: 'Cannot delete system style presets' });
      }

      // Clear any projects referencing this preset
      await fastify.db('projects')
        .where({ default_style_preset_id: id })
        .update({ default_style_preset_id: null });

      await fastify.db('style_presets').where({ id }).del();

      return { message: 'Style preset deleted' };
    },
  });

  // --- Extract style from prompt (T018) ---
  fastify.post('/api/styles/extract', {
    schema: {
      description: 'Extract visual style elements from a prompt using Claude',
      tags: ['styles'],
      body: {
        type: 'object',
        required: ['prompt'],
        properties: {
          prompt: { type: 'string', minLength: 1, maxLength: 4000 },
        },
      },
      response: { 200: extractedStyleSchema },
    },
    handler: async (request, reply) => {
      const { prompt } = request.body;

      if (!config.ai.anthropicApiKey) {
        return reply.code(503).send({
          error: 'service_unavailable',
          message: 'Anthropic API key not configured',
        });
      }

      const anthropic = new Anthropic({ apiKey: config.ai.anthropicApiKey });

      const systemPrompt = `Extract the visual style elements from this image generation prompt. Separate the style (lighting, composition, color, mood, texture, technique) from the subject matter. Return a JSON object with: name (short style name, 2-4 words), description (one sentence describing the style), promptModifier (just the style elements that can be applied to any subject), category (one of: cinematic, photography, illustration, digital-art, retro, abstract).`;

      try {
        const message = await anthropic.messages.create({
          model: 'claude-3-5-haiku-latest',
          max_tokens: 512,
          system: systemPrompt,
          messages: [
            { role: 'user', content: prompt },
          ],
        });

        const text = message.content[0]?.text || '';
        // Extract JSON from the response (handle potential markdown code blocks)
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (!jsonMatch) {
          return reply.code(500).send({
            error: 'extraction_failed',
            message: 'Failed to extract style from prompt',
          });
        }

        const extracted = JSON.parse(jsonMatch[0]);

        // Validate category
        if (!VALID_CATEGORIES.includes(extracted.category)) {
          extracted.category = 'abstract';
        }

        return {
          name: extracted.name || 'Custom Style',
          description: extracted.description || '',
          promptModifier: extracted.promptModifier || '',
          category: extracted.category,
        };
      } catch (err) {
        fastify.log.error({ err }, 'Style extraction failed');
        return reply.code(500).send({
          error: 'extraction_failed',
          message: 'Failed to extract style from prompt',
        });
      }
    },
  });
}
