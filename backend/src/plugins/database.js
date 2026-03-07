import fp from 'fastify-plugin';
import knex from 'knex';
import config from '../config.js';

async function database(fastify) {
  const db = knex({
    client: 'pg',
    connection: config.db.connectionString,
    pool: { min: 2, max: 10 },
  });

  // Verify connection
  await db.raw('SELECT 1');
  fastify.log.info('Database connected');

  fastify.decorate('db', db);

  fastify.addHook('onClose', async () => {
    await db.destroy();
    fastify.log.info('Database pool destroyed');
  });
}

export default fp(database, { name: 'database' });
