export async function up(knex) {
  await knex.schema.alterTable('assets', (t) => {
    t.timestamp('updated_at').defaultTo(knex.fn.now()).notNullable();
  });
}

export async function down(knex) {
  await knex.schema.alterTable('assets', (t) => {
    t.dropColumn('updated_at');
  });
}
