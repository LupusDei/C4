import config from './src/config.js';

export default {
  client: 'pg',
  connection: config.db.connectionString,
  pool: {
    min: 2,
    max: 10,
  },
  migrations: {
    directory: './src/db/migrations',
  },
};
