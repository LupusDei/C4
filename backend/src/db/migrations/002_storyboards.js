export async function up(knex) {
  await knex.schema.createTable('storyboards', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('project_id').notNullable().references('id').inTable('projects').onDelete('CASCADE');
    t.string('title', 255).notNullable();
    t.text('script_text');
    t.string('status', 20).defaultTo('draft').notNullable();
    t.jsonb('metadata').defaultTo('{}');
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();

    t.index('project_id');
  });

  await knex.raw(`
    ALTER TABLE storyboards
    ADD CONSTRAINT storyboards_status_check
    CHECK (status IN ('draft', 'generating', 'complete', 'assembled', 'failed'))
  `);

  await knex.schema.createTable('scenes', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('storyboard_id').notNullable().references('id').inTable('storyboards').onDelete('CASCADE');
    t.integer('order_index').notNullable();
    t.text('narration_text').notNullable().defaultTo('');
    t.text('visual_prompt').notNullable().defaultTo('');
    t.decimal('duration_seconds', 6, 2).notNullable().defaultTo(5.0);
    t.uuid('asset_id').references('id').inTable('assets').onDelete('SET NULL');
    t.jsonb('variations').defaultTo('[]');
    t.jsonb('metadata').defaultTo('{}');
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();

    t.index(['storyboard_id', 'order_index']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('scenes');
  await knex.schema.dropTableIfExists('storyboards');
}
