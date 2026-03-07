import Fastify from 'fastify';
import fp from 'fastify-plugin';
import { randomUUID } from 'node:crypto';

/**
 * Build a Fastify instance with mock plugins for testing.
 * Mocks: db (knex-like), generationQueue, ws, storage.
 */
export async function buildTestApp() {
  const fastify = Fastify({ logger: false });

  // In-memory data store
  const store = {
    projects: [],
    assets: [],
    credit_accounts: [{ id: randomUUID(), balance: 100, created_at: new Date(), updated_at: new Date() }],
    credit_transactions: [],
    notes: [],
  };

  // Mock knex-like DB
  const mockDb = createMockDb(store);
  await fastify.register(fp(async (f) => {
    f.decorate('db', mockDb);
  }));

  // Mock BullMQ queue
  const jobs = [];
  await fastify.register(fp(async (f) => {
    f.decorate('generationQueue', {
      add: async (name, data, opts) => {
        jobs.push({ name, data, opts });
        return { id: opts?.jobId || 'test-job' };
      },
    });
  }));

  // Mock WebSocket
  await fastify.register(fp(async (f) => {
    f.decorate('ws', { broadcast: () => {} });
  }));

  // Mock storage
  await fastify.register(fp(async (f) => {
    f.decorate('storage', {
      deleteFile: async () => {},
      savePath: './storage',
    });
  }));

  // Register routes
  const { default: generateRoutes } = await import('../src/routes/generate.js');
  const { default: projectRoutes } = await import('../src/routes/projects.js');
  const { default: creditRoutes } = await import('../src/routes/credits.js');
  const { default: assembleRoutes } = await import('../src/routes/assemble.js');

  await fastify.register(generateRoutes);
  await fastify.register(projectRoutes);
  await fastify.register(creditRoutes);
  await fastify.register(assembleRoutes);

  await fastify.ready();
  return { fastify, store, jobs };
}

/**
 * Knex-like mock that supports chained query patterns:
 *   db('table').where({}).first()
 *   db('table').insert({}).returning('*')
 *   db('table').where({}).update({}).returning('*')
 *   db('table').where({}).del()
 *   db('table').where({}).count('* as count')
 *   db('table').decrement/increment(field, amount).update({})
 *   db.raw(sql, bindings), db.fn.now()
 *   db.transaction(async trx => { ... })
 */
function createMockDb(store) {
  function db(table) {
    return new QueryBuilder(store, table, db);
  }

  db.fn = { now: () => new Date() };
  db.raw = (sql, bindings) => sql;
  db.transaction = async (fn) => fn(db);

  return db;
}

class QueryBuilder {
  constructor(store, table, db) {
    this._store = store;
    this._table = table;
    this._db = db;
    this._where = {};
    this._whereIn = null;
    this._pendingResult = null;
  }

  where(conditions) {
    if (typeof conditions === 'object') {
      this._where = { ...this._where, ...conditions };
    }
    return this;
  }

  whereIn(field, values) {
    this._whereIn = { field, values };
    return this;
  }

  andWhere(conditions) { return this.where(conditions); }
  forUpdate() { return this; }
  orderBy() { return this; }
  select() { return this; }
  leftJoin() { return this; }
  groupBy() { return this; }
  as() { return this; }
  limit() { return this; }
  offset() { return this; }

  async first() {
    const rows = this._filter();
    return rows[0] || null;
  }

  // Make QueryBuilder itself thenable — resolves to filtered rows
  then(resolve, reject) {
    try {
      if (this._pendingResult !== null) {
        resolve(this._pendingResult);
      } else {
        resolve(this._filter());
      }
    } catch (e) {
      reject(e);
    }
  }

  _filter() {
    let rows = this._store[this._table] || [];
    for (const [key, val] of Object.entries(this._where)) {
      rows = rows.filter((r) => r[key] === val);
    }
    if (this._whereIn) {
      rows = rows.filter((r) => this._whereIn.values.includes(r[this._whereIn.field]));
    }
    return rows;
  }

  insert(data) {
    const row = {
      id: data.id || randomUUID(),
      ...data,
      created_at: data.created_at || new Date(),
      updated_at: new Date(),
    };
    if (!this._store[this._table]) this._store[this._table] = [];
    this._store[this._table].push(row);
    this._pendingResult = [row];
    return this; // allow .returning('*') chain
  }

  returning() {
    // _pendingResult already set by insert() or update()
    return this; // still thenable — resolves via then()
  }

  update(data) {
    const rows = this._filter();
    for (const row of rows) {
      Object.assign(row, data);
    }
    this._pendingResult = rows;
    return this; // allow .returning('*') chain
  }

  async del() {
    const toDelete = new Set(this._filter().map((r) => r.id));
    this._store[this._table] = (this._store[this._table] || []).filter((r) => !toDelete.has(r.id));
    return toDelete.size;
  }

  count() {
    const rows = this._filter();
    this._pendingResult = [{ count: rows.length }];
    return this;
  }

  decrement(field, amount) {
    const rows = this._filter();
    for (const row of rows) {
      row[field] = (row[field] || 0) - amount;
    }
    this._pendingResult = rows;
    return this;
  }

  increment(field, amount) {
    const rows = this._filter();
    for (const row of rows) {
      row[field] = (row[field] || 0) + amount;
    }
    this._pendingResult = rows;
    return this;
  }
}
