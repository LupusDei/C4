export async function up(knex) {
  await knex.raw('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');

  await knex.schema.createTable('projects', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.string('title').notNullable();
    t.text('description');
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();
  });

  await knex.schema.createTable('assets', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.uuid('project_id').notNullable().references('id').inTable('projects').onDelete('CASCADE');
    t.enu('type', ['image', 'video']).notNullable();
    t.text('prompt');
    t.string('provider');
    t.string('quality_tier');
    t.string('file_path');
    t.string('thumbnail_path');
    t.integer('credit_cost').defaultTo(0);
    t.enu('status', ['pending', 'processing', 'complete', 'failed']).defaultTo('pending').notNullable();
    t.jsonb('metadata').defaultTo('{}');
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();

    t.index('project_id');
    t.index('status');
  });

  await knex.schema.createTable('notes', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.uuid('project_id').notNullable().references('id').inTable('projects').onDelete('CASCADE');
    t.text('content').notNullable();
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();

    t.index('project_id');
  });

  await knex.schema.createTable('credit_accounts', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.integer('balance').defaultTo(100).notNullable();
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();
  });

  await knex.schema.createTable('credit_transactions', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.uuid('account_id').notNullable().references('id').inTable('credit_accounts').onDelete('CASCADE');
    t.enu('type', ['debit', 'credit', 'refund']).notNullable();
    t.integer('amount').notNullable();
    t.string('description');
    t.jsonb('metadata').defaultTo('{}');
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();

    t.index('account_id');
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('credit_transactions');
  await knex.schema.dropTableIfExists('credit_accounts');
  await knex.schema.dropTableIfExists('notes');
  await knex.schema.dropTableIfExists('assets');
  await knex.schema.dropTableIfExists('projects');
}
