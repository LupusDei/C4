const uuidFormat = { type: 'string', format: 'uuid' };

const projectSchema = {
  type: 'object',
  properties: {
    id: uuidFormat,
    title: { type: 'string' },
    description: { type: ['string', 'null'] },
    asset_count: { type: 'integer' },
    created_at: { type: 'string', format: 'date-time' },
    updated_at: { type: 'string', format: 'date-time' },
  },
};

const projectListSchema = {
  type: 'array',
  items: projectSchema,
};

export default async function projectRoutes(fastify) {
  // --- Create project ---
  fastify.post('/api/projects', {
    schema: {
      description: 'Create a new project',
      tags: ['projects'],
      body: {
        type: 'object',
        required: ['title'],
        properties: {
          title: { type: 'string', minLength: 1, maxLength: 255 },
          description: { type: 'string', maxLength: 2000 },
        },
      },
      response: { 201: projectSchema },
    },
    handler: async (request, reply) => {
      const { title, description } = request.body;
      const [project] = await fastify.db('projects')
        .insert({ title, description })
        .returning('*');

      return reply.code(201).send({ ...project, asset_count: 0 });
    },
  });

  // --- List all projects ---
  fastify.get('/api/projects', {
    schema: {
      description: 'List all projects',
      tags: ['projects'],
      response: { 200: projectListSchema },
    },
    handler: async () => {
      const projects = await fastify.db('projects')
        .select(
          'projects.*',
          fastify.db.raw('COALESCE(a.cnt, 0)::int as asset_count'),
        )
        .leftJoin(
          fastify.db('assets')
            .select('project_id')
            .count('* as cnt')
            .groupBy('project_id')
            .as('a'),
          'projects.id',
          'a.project_id',
        )
        .orderBy('projects.updated_at', 'desc');

      return projects;
    },
  });

  // --- Get single project ---
  fastify.get('/api/projects/:id', {
    schema: {
      description: 'Get a single project by ID',
      tags: ['projects'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      response: { 200: projectSchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;

      const project = await fastify.db('projects').where({ id }).first();
      if (!project) {
        return reply.code(404).send({ error: 'not_found', message: 'Project not found' });
      }

      const [{ count }] = await fastify.db('assets')
        .where({ project_id: id })
        .count('* as count');

      return { ...project, asset_count: parseInt(count, 10) };
    },
  });

  // --- Update project ---
  fastify.put('/api/projects/:id', {
    schema: {
      description: 'Update a project',
      tags: ['projects'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      body: {
        type: 'object',
        properties: {
          title: { type: 'string', minLength: 1, maxLength: 255 },
          description: { type: 'string', maxLength: 2000 },
        },
      },
      response: { 200: projectSchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const updates = { ...request.body, updated_at: fastify.db.fn.now() };

      const [project] = await fastify.db('projects')
        .where({ id })
        .update(updates)
        .returning('*');

      if (!project) {
        return reply.code(404).send({ error: 'not_found', message: 'Project not found' });
      }

      return project;
    },
  });

  // --- Delete project ---
  fastify.delete('/api/projects/:id', {
    schema: {
      description: 'Delete a project and all its assets and notes',
      tags: ['projects'],
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

      // Delete asset files from storage before removing DB records
      const assets = await fastify.db('assets').where({ project_id: id });
      for (const asset of assets) {
        if (asset.file_path) await fastify.storage.deleteFile(asset.file_path);
        if (asset.thumbnail_path) await fastify.storage.deleteFile(asset.thumbnail_path);
      }

      const deleted = await fastify.db('projects').where({ id }).del();
      if (!deleted) {
        return reply.code(404).send({ error: 'not_found', message: 'Project not found' });
      }

      return { message: 'Project deleted' };
    },
  });
}
