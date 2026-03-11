export async function up(knex) {
  await knex.schema.createTable('storyboards', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.uuid('project_id').notNullable().references('id').inTable('projects').onDelete('CASCADE');
    t.string('title').notNullable();
    t.text('script');
    t.enu('status', ['draft', 'generating', 'assembled', 'failed']).defaultTo('draft').notNullable();
    t.jsonb('metadata').defaultTo('{}');
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();

    t.index('project_id');
  });

  await knex.schema.createTable('scenes', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.uuid('storyboard_id').notNullable().references('id').inTable('storyboards').onDelete('CASCADE');
    t.integer('scene_number').notNullable();
    t.text('visual_prompt').notNullable();
    t.text('narration_text');
    t.float('duration_seconds').defaultTo(5);
    t.uuid('asset_id').references('id').inTable('assets').onDelete('SET NULL');
    t.jsonb('variations').defaultTo('[]');
    t.jsonb('metadata').defaultTo('{}');
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();

    t.index('storyboard_id');
    t.unique(['storyboard_id', 'scene_number']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('scenes');
  await knex.schema.dropTableIfExists('storyboards');
}
