const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../utils/db');

/**
 * @route GET /api/accounts
 * @desc Get all user accounts (Encrypted)
 */
router.get('/', verifyToken, async (req, res) => {
    try {
        const result = await db.query(
            'SELECT id, encrypted_name, encrypted_balance, currency, type, provider_id FROM accounts WHERE user_id = $1',
            [req.user.uid]
        );
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/accounts
 * @desc Create a new private account
 */
router.post('/', verifyToken, async (req, res) => {
    const { encryptedName, encryptedBalance, currency, type, providerId } = req.body;

    try {
        const result = await db.query(
            `INSERT INTO accounts (user_id, encrypted_name, encrypted_balance, currency, type, provider_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id`,
            [req.user.uid, encryptedName, encryptedBalance, currency, type || 'checking', providerId]
        );
        res.json({ id: result.rows[0].id, message: 'Account created successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
