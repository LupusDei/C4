import 'dotenv/config';

const required = [
  'DATABASE_URL',
  'REDIS_URL',
];

const missing = required.filter((key) => !process.env[key]);
if (missing.length > 0) {
  throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
}

const config = Object.freeze({
  server: {
    port: parseInt(process.env.PORT || '3000', 10),
    host: process.env.HOST || '0.0.0.0',
  },

  db: {
    connectionString: process.env.DATABASE_URL,
  },

  redis: {
    url: process.env.REDIS_URL,
  },

  ai: {
    openaiApiKey: process.env.OPENAI_API_KEY || '',
    xaiApiKey: process.env.XAI_API_KEY || '',
    falKey: process.env.FAL_KEY || '',
    runwayApiKey: process.env.RUNWAY_API_KEY || '',
    creatomateApiKey: process.env.CREATOMATE_API_KEY || '',
    deepgramApiKey: process.env.DEEPGRAM_API_KEY || '',
  },

  storage: {
    path: process.env.STORAGE_PATH || './storage',
  },
});

export default config;
