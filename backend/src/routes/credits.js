import { ensureAccount, getBalance, getHistory } from '../services/credits.js';

const balanceSchema = {
  type: 'object',
  properties: {
    account_id: { type: 'string', format: 'uuid' },
    balance: { type: 'integer' },
  },
};

const transactionSchema = {
  type: 'object',
  properties: {
    id: { type: 'string', format: 'uuid' },
    account_id: { type: 'string', format: 'uuid' },
    type: { type: 'string', enum: ['debit', 'credit', 'refund'] },
    amount: { type: 'integer' },
    description: { type: ['string', 'null'] },
    metadata: { type: 'object' },
    created_at: { type: 'string', format: 'date-time' },
  },
};

const historySchema = {
  type: 'object',
  properties: {
    data: { type: 'array', items: transactionSchema },
    total: { type: 'integer' },
    limit: { type: 'integer' },
    offset: { type: 'integer' },
  },
};

export default async function creditRoutes(fastify) {
  // --- Get balance ---
  fastify.get('/api/credits/balance', {
    schema: {
      description: 'Get the current credit balance',
      tags: ['credits'],
      response: { 200: balanceSchema },
    },
    handler: async (request, reply) => {
      const account = await ensureAccount(fastify.db);
      const balance = await getBalance(fastify.db, account.id);
      return { account_id: account.id, balance };
    },
  });

  // --- Get transaction history ---
  fastify.get('/api/credits/history', {
    schema: {
      description: 'Get credit transaction history',
      tags: ['credits'],
      querystring: {
        type: 'object',
        properties: {
          limit: { type: 'integer', minimum: 1, maximum: 100, default: 50 },
          offset: { type: 'integer', minimum: 0, default: 0 },
        },
      },
      response: { 200: historySchema },
    },
    handler: async (request) => {
      const { limit, offset } = request.query;
      const account = await ensureAccount(fastify.db);

      const [transactions, [{ count }]] = await Promise.all([
        getHistory(fastify.db, account.id, limit, offset),
        fastify.db('credit_transactions')
          .where({ account_id: account.id })
          .count('* as count'),
      ]);

      return {
        data: transactions,
        total: parseInt(count, 10),
        limit,
        offset,
      };
    },
  });

  // --- Allocate free-tier credits ---
  fastify.post('/api/credits/allocate', {
    schema: {
      description: 'Allocate free-tier credits (idempotent — only creates account if none exists)',
      tags: ['credits'],
      response: {
        200: {
          type: 'object',
          properties: {
            account_id: { type: 'string', format: 'uuid' },
            balance: { type: 'integer' },
            created: { type: 'boolean' },
          },
        },
      },
    },
    handler: async () => {
      const existing = await fastify.db('credit_accounts').first();
      if (existing) {
        return { account_id: existing.id, balance: existing.balance, created: false };
      }

      const account = await ensureAccount(fastify.db);
      return { account_id: account.id, balance: account.balance, created: true };
    },
  });
}
