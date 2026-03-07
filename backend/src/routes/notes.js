const uuidFormat = { type: 'string', format: 'uuid' };

const noteSchema = {
  type: 'object',
  properties: {
    id: uuidFormat,
    project_id: uuidFormat,
    content: { type: 'string' },
    created_at: { type: 'string', format: 'date-time' },
    updated_at: { type: 'string', format: 'date-time' },
  },
};

const noteListSchema = {
  type: 'array',
  items: noteSchema,
};

export default async function noteRoutes(fastify) {
  // --- Create note ---
  fastify.post('/api/projects/:projectId/notes', {
    schema: {
      description: 'Add a note to a project',
      tags: ['notes'],
      params: {
        type: 'object',
        required: ['projectId'],
        properties: { projectId: uuidFormat },
      },
      body: {
        type: 'object',
        required: ['content'],
        properties: {
          content: { type: 'string', minLength: 1, maxLength: 10000 },
        },
      },
      response: { 201: noteSchema },
    },
    handler: async (request, reply) => {
      const { projectId } = request.params;
      const { content } = request.body;

      // Verify project exists
      const project = await fastify.db('projects').where({ id: projectId }).first();
      if (!project) {
        return reply.code(404).send({ error: 'not_found', message: 'Project not found' });
      }

      const [note] = await fastify.db('notes')
        .insert({ project_id: projectId, content })
        .returning('*');

      return reply.code(201).send(note);
    },
  });

  // --- List notes for project ---
  fastify.get('/api/projects/:projectId/notes', {
    schema: {
      description: 'List notes for a project',
      tags: ['notes'],
      params: {
        type: 'object',
        required: ['projectId'],
        properties: { projectId: uuidFormat },
      },
      response: { 200: noteListSchema },
    },
    handler: async (request) => {
      const { projectId } = request.params;

      return fastify.db('notes')
        .where({ project_id: projectId })
        .orderBy('created_at', 'desc');
    },
  });

  // --- Update note ---
  fastify.put('/api/notes/:id', {
    schema: {
      description: 'Update a note',
      tags: ['notes'],
      params: {
        type: 'object',
        required: ['id'],
        properties: { id: uuidFormat },
      },
      body: {
        type: 'object',
        required: ['content'],
        properties: {
          content: { type: 'string', minLength: 1, maxLength: 10000 },
        },
      },
      response: { 200: noteSchema },
    },
    handler: async (request, reply) => {
      const { id } = request.params;
      const { content } = request.body;

      const [note] = await fastify.db('notes')
        .where({ id })
        .update({ content, updated_at: fastify.db.fn.now() })
        .returning('*');

      if (!note) {
        return reply.code(404).send({ error: 'not_found', message: 'Note not found' });
      }

      return note;
    },
  });

  // --- Delete note ---
  fastify.delete('/api/notes/:id', {
    schema: {
      description: 'Delete a note',
      tags: ['notes'],
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
      const deleted = await fastify.db('notes').where({ id: request.params.id }).del();
      if (!deleted) {
        return reply.code(404).send({ error: 'not_found', message: 'Note not found' });
      }
      return { message: 'Note deleted' };
    },
  });
}
