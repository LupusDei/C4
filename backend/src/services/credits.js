export async function ensureAccount(db) {
  const existing = await db('credit_accounts').first();
  if (existing) return existing;

  const [account] = await db('credit_accounts')
    .insert({ balance: 100 })
    .returning('*');
  return account;
}

export async function getBalance(db, accountId) {
  const account = await db('credit_accounts').where({ id: accountId }).first();
  if (!account) throw new Error('Account not found');
  return account.balance;
}

export async function deduct(db, accountId, amount, description) {
  return db.transaction(async (trx) => {
    const account = await trx('credit_accounts')
      .where({ id: accountId })
      .forUpdate()
      .first();

    if (!account) throw new Error('Account not found');
    if (account.balance < amount) {
      const err = new Error('Insufficient credits');
      err.statusCode = 402;
      throw err;
    }

    await trx('credit_accounts')
      .where({ id: accountId })
      .update({
        balance: account.balance - amount,
        updated_at: trx.fn.now(),
      });

    const [transaction] = await trx('credit_transactions')
      .insert({
        account_id: accountId,
        type: 'debit',
        amount,
        description,
        metadata: JSON.stringify({}),
      })
      .returning('*');

    return transaction;
  });
}

export async function refund(db, accountId, transactionId) {
  return db.transaction(async (trx) => {
    const original = await trx('credit_transactions')
      .where({ id: transactionId, account_id: accountId, type: 'debit' })
      .first();

    if (!original) throw new Error('Transaction not found');

    await trx('credit_accounts')
      .where({ id: accountId })
      .increment('balance', original.amount)
      .update({ updated_at: trx.fn.now() });

    const [transaction] = await trx('credit_transactions')
      .insert({
        account_id: accountId,
        type: 'refund',
        amount: original.amount,
        description: `Refund for: ${original.description || transactionId}`,
        metadata: JSON.stringify({ original_transaction_id: transactionId }),
      })
      .returning('*');

    return transaction;
  });
}

export async function getHistory(db, accountId, limit = 50, offset = 0) {
  return db('credit_transactions')
    .where({ account_id: accountId })
    .orderBy('created_at', 'desc')
    .limit(limit)
    .offset(offset);
}
