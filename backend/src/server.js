import Fastify from 'fastify';
import cors from '@fastify/cors';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import config from './config.js';
import database from './plugins/database.js';
import redis from './plugins/redis.js';
import storage from './plugins/storage.js';
import websocket from './plugins/websocket.js';
import generateRoutes from './routes/generate.js';
import projectRoutes from './routes/projects.js';
import assetRoutes from './routes/assets.js';
import noteRoutes from './routes/notes.js';
import creditRoutes from './routes/credits.js';
import assembleRoutes from './routes/assemble.js';
import storyboardRoutes from './routes/storyboards.js';
import styleRoutes from './routes/styles.js';
import promptRoutes from './routes/prompts.js';
import errorHandler from './plugins/errors.js';
import { createGenerationWorker } from './workers/generation.js';

const fastify = Fastify({
  logger: {
    transport: {
      target: 'pino-pretty',
      options: { colorize: true },
    },
  },
});

// --- Plugins ---
await fastify.register(cors, { origin: true });

await fastify.register(swagger, {
  openapi: {
    info: {
      title: 'C4 Content Creation Coordinator',
      version: '0.1.0',
      description: 'AI-powered content creation API',
    },
  },
});

await fastify.register(swaggerUi, { routePrefix: '/docs' });

await fastify.register(errorHandler);
await fastify.register(database);
await fastify.register(redis);
await fastify.register(storage);
await fastify.register(websocket);

// --- Routes ---
await fastify.register(generateRoutes);
await fastify.register(projectRoutes);
await fastify.register(assetRoutes);
await fastify.register(noteRoutes);
await fastify.register(creditRoutes);
await fastify.register(assembleRoutes);
await fastify.register(storyboardRoutes);
await fastify.register(styleRoutes);
await fastify.register(promptRoutes);

// --- Health check ---
fastify.get('/health', async () => ({ status: 'ok' }));

// --- Start ---
let generationWorker;

async function start() {
  try {
    await fastify.listen({ port: config.server.port, host: config.server.host });

    // Start BullMQ worker after server is ready (plugins are loaded)
    generationWorker = createGenerationWorker({
      db: fastify.db,
      wsBroadcast: fastify.ws.broadcast,
      storagePath: config.storage.path,
    });
    fastify.log.info('Generation worker started (concurrency: 2)');

    fastify.log.info(`Server listening on http://${config.server.host}:${config.server.port}`);
    fastify.log.info(`API docs available at http://${config.server.host}:${config.server.port}/docs`);
  } catch (err) {
    fastify.log.fatal(err);
    process.exit(1);
  }
}

async function shutdown(signal) {
  fastify.log.info({ signal }, 'Received signal, shutting down');
  if (generationWorker) await generationWorker.close();
  await fastify.close();
  process.exit(0);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

start();
