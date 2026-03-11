const uuidFormat = { type: 'string', format: 'uuid' };

const promptHistorySchema = {
  type: 'object',
  properties: {
    id: uuidFormat,
    project_id: { type: ['string', 'null'], format: 'uuid' },
    original_prompt: { type: 'string' },
    enhanced_prompt: { type: ['string', 'null'] },
    provider: { type: 'string' },
    generation_type: { type: 'string' },
    style_preset_id: { type: ['string', 'null'] },
    asset_id: { type: ['string', 'null'] },
    kept: { type: 'boolean' },
    created_at: { type: 'string', format: 'date-time' },
  },
};

const promptHistoryListResponseSchema = {
  type: 'object',
  properties: {
    items: { type: 'array', items: promptHistorySchema },
    total: { type: 'integer' },
    limit: { type: 'integer' },
    offset: { type: 'integer' },
  },
};

export default async function promptRoutes(fastify) {
  // --- List prompt history ---
  fastify.get('/api/prompts/history', {
    schema: {
      description: 'List prompt history (paginated, searchable)',
      tags: ['prompts'],
      querystring: {
        type: 'object',
        properties: {
          limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
          offset: { type: 'integer', minimum: 0, default: 0 },
          search: { type: 'string', maxLength: 500 },
          projectId: { type: 'string', format: 'uuid' },
        },
      },
      response: { 200: promptHistoryListResponseSchema },
    },
    handler: async (request) => {
      const { limit = 20, offset = 0, search, projectId } = request.query;

      let baseQuery = fastify.db('prompt_history');

      if (projectId) {
        baseQuery = baseQuery.where('project_id', projectId);
      }

      if (search) {
        const sanitized = search.replace(/[%_]/g, '\\$&');
        baseQuery = baseQuery.where(function () {
          this.where('original_prompt', 'ilike', `%${sanitized}%`)
            .orWhere('enhanced_prompt', 'ilike', `%${sanitized}%`);
        });
      }

      const [{ count }] = await baseQuery.clone().count('* as count');
      const items = await baseQuery.orderBy('created_at', 'desc').limit(limit).offset(offset);

      return { items, total: parseInt(count, 10), limit, offset };
    },
  });

  // --- Get single prompt history entry ---
  fastify.get('/api/prompts/history/:id', {
    schema: {
      description: 'Get a single prompt history entry',
      tags: ['prompts'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      response: { 200: promptHistorySchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;

      const entry = await fastify.db('prompt_history').where({ id }).first();
      if (!entry) {
        return reply.code(404).send({ error: 'not_found', message: 'Prompt history entry not found' });
      }

      return entry;
    },
  });

  // --- Delete prompt history entry ---
  fastify.delete('/api/prompts/history/:id', {
    schema: {
      description: 'Delete a prompt history entry',
      tags: ['prompts'],
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

      const deleted = await fastify.db('prompt_history').where({ id }).del();
      if (!deleted) {
        return reply.code(404).send({ error: 'not_found', message: 'Prompt history entry not found' });
      }

      return { message: 'Prompt history entry deleted' };
    },
  });
}
