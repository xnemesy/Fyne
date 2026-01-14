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
    date 
  } = req.body;

  if (!accountId || !amount || !categoryUuid) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    await db.ensureUser(req.user.uid);
    
    // We use a custom insert for manual transactions to handle the specific fields
    const query = `
      INSERT INTO transactions (
        account_id, user_id, amount, currency, 
        encrypted_description, encrypted_counter_party, category_uuid, 
        booking_date, external_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id
    `;

    // For manual transactions, we generate a unique local external_id
    const externalId = `manual_${Date.now()}_${Math.random().toString(36).substring(7)}`;

    const result = await db.query(query, [
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

    res.json({ 
      id: result.rows[0].id, 
      message: 'Transaction saved and budgets updated via trigger' 
    });
  } catch (error) {
    console.error('Manual Transaction Error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
