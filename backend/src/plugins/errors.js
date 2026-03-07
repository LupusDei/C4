import fp from 'fastify-plugin';

export default fp(async function errorHandler(fastify) {
  fastify.setErrorHandler((error, request, reply) => {
    const statusCode = error.statusCode || 500;

    // Fastify validation errors
    if (error.validation) {
      request.log.warn({ validation: error.validation }, 'Validation error');
      return reply.code(400).send({
        error: 'validation_error',
        message: error.message,
        statusCode: 400,
      });
    }

    // Rate limit errors
    if (statusCode === 429) {
      request.log.warn('Rate limit exceeded');
      return reply.code(429).send({
        error: 'rate_limit',
        message: 'Too many requests, please try again later',
        statusCode: 429,
      });
    }

    // Not found
    if (statusCode === 404) {
      return reply.code(404).send({
        error: 'not_found',
        message: error.message || 'Resource not found',
        statusCode: 404,
      });
    }

    // Client errors (4xx)
    if (statusCode >= 400 && statusCode < 500) {
      request.log.warn({ err: error }, 'Client error');
      return reply.code(statusCode).send({
        error: error.code || 'client_error',
        message: error.message,
        statusCode,
      });
    }

    // Server errors (5xx) — log full stack
    request.log.error({ err: error }, 'Internal server error');
    return reply.code(statusCode).send({
      error: 'internal_error',
      message: process.env.NODE_ENV === 'production'
        ? 'An internal error occurred'
        : error.message,
      statusCode,
    });
  });

  // 404 handler for unknown routes
  fastify.setNotFoundHandler((request, reply) => {
    reply.code(404).send({
      error: 'not_found',
      message: `Route ${request.method} ${request.url} not found`,
      statusCode: 404,
    });
  });
});
