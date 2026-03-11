export async function up(knex) {
  await knex.schema.createTable('style_presets', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.string('name', 100).notNullable();
    t.text('description');
    t.text('prompt_modifier').notNullable();
    t.string('category', 50).notNullable();
    t.text('thumbnail_url');
    t.boolean('is_custom').defaultTo(false).notNullable();
    t.string('user_id', 100);
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();

    t.index('category');
    t.index('user_id');
  });

  await knex.schema.createTable('prompt_history', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    t.uuid('project_id').references('id').inTable('projects').onDelete('CASCADE');
    t.text('original_prompt').notNullable();
    t.text('enhanced_prompt');
    t.string('provider', 50).notNullable();
    t.string('generation_type', 20).notNullable().defaultTo('image'); // 'image' or 'video'
    t.uuid('style_preset_id').references('id').inTable('style_presets').onDelete('SET NULL');
    t.uuid('asset_id').references('id').inTable('assets').onDelete('SET NULL');
    t.boolean('kept').defaultTo(true).notNullable();
    t.timestamp('created_at').defaultTo(knex.fn.now()).notNullable();

    t.index('project_id');
    t.index('style_preset_id');
    t.index('asset_id');
    t.index('created_at');
  });

  await knex.schema.alterTable('projects', (t) => {
    t.uuid('default_style_preset_id').references('id').inTable('style_presets').onDelete('SET NULL');
  });
}

export async function down(knex) {
  await knex.schema.alterTable('projects', (t) => {
    t.dropColumn('default_style_preset_id');
  });
  await knex.schema.dropTableIfExists('prompt_history');
  await knex.schema.dropTableIfExists('style_presets');
}
