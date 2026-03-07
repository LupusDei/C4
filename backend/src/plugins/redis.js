import fp from 'fastify-plugin';
import Redis from 'ioredis';
import { Queue } from 'bullmq';
import config from '../config.js';

async function redis(fastify) {
  const connection = new Redis(config.redis.url, {
    maxRetriesPerRequest: null,
  });

  connection.on('error', (err) => fastify.log.error({ err }, 'Redis error'));

  // Wait for connection
  await new Promise((resolve, reject) => {
    connection.once('ready', resolve);
    connection.once('error', reject);
  });
  fastify.log.info('Redis connected');

  const generationQueue = new Queue('generation', { connection });

  fastify.decorate('redis', connection);
  fastify.decorate('generationQueue', generationQueue);

  fastify.addHook('onClose', async () => {
    await generationQueue.close();
    await connection.quit();
    fastify.log.info('Redis disconnected');
  });
}

export default fp(redis, { name: 'redis' });
