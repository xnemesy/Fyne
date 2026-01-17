const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../utils/db');

/**
 * @route POST /api/transactions/manual
 * @desc Create a manual transaction (encrypted payload + anonymous category)
 */
router.post('/manual', verifyToken, async (req, res) => {
  const {
    accountId,
    amount,
    currency,
    encryptedDescription,
    encryptedCounterParty,
    categoryUuid,
    date,
    encryptedNewBalance
  } = req.body;

  if (!accountId || !amount || !categoryUuid) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    await db.ensureUser(req.user.uid);

    // 1. Insert Transaction
    const txQuery = `
      INSERT INTO transactions (
        account_id, user_id, amount, currency, 
        encrypted_description, encrypted_counter_party, category_uuid, 
        booking_date, external_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id
    `;

    const externalId = `manual_${Date.now()}_${Math.random().toString(36).substring(7)}`;

    const txResult = await client.query(txQuery, [
      accountId,
      req.user.uid,
      amount,
      currency || 'EUR',
      encryptedDescription,
      encryptedCounterParty || '',
      categoryUuid,
      date || new Date(),
      externalId
    ]);

    // 2. Optionally update Account Balance (Client-calculated & encrypted)
    if (encryptedNewBalance) {
      await client.query(
        'UPDATE accounts SET encrypted_balance = $1 WHERE id = $2 AND user_id = $3',
        [encryptedNewBalance, accountId, req.user.uid]
      );
    }

    await client.query('COMMIT');

    res.json({
      id: txResult.rows[0].id,
      message: 'Transaction saved and balance updated'
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Manual Transaction Error:', error);
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
});

/**
 * @route GET /api/transactions
 * @desc Get all transactions for the user
 */
router.get('/', verifyToken, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT id, account_id, amount, currency, encrypted_description, encrypted_counter_party, category_uuid, booking_date, external_id FROM transactions WHERE user_id = $1 ORDER BY booking_date DESC',
      [req.user.uid]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * @route POST /api/transactions/delete
 * @desc Delete a transaction
 */
router.post('/delete', verifyToken, async (req, res) => {
  const { id } = req.body;

  if (!id) {
    return res.status(400).json({ error: 'Missing transaction ID' });
  }

  try {
    const result = await db.query(
      'DELETE FROM transactions WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, req.user.uid]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Transaction not found or unauthorized' });
    }

    res.json({ message: 'Transaction deleted successfully', id });
  } catch (error) {
    console.error('Delete Transaction Error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
