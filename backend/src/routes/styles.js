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

      let query = fastify.db('style_presets')
        .where(function () {
          this.where('is_custom', false).orWhereNull('user_id');
        })
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

      await fastify.db('style_presets').where({ id }).del();

      return { message: 'Style preset deleted' };
    },
  });
}
