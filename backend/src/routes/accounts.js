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
        await db.ensureUser(req.user.uid);
        // Ensure group_name column exists (migration)
        await db.query(`
            ALTER TABLE accounts ADD COLUMN IF NOT EXISTS group_name VARCHAR(50) DEFAULT 'Personale'
        `);

        const result = await db.query(
            'SELECT id, encrypted_name, encrypted_balance, currency, type, provider_id, group_name FROM accounts WHERE user_id = $1',
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
    const {
        encrypted_name,
        encrypted_balance,
        currency,
        type,
        provider_id
    } = req.body;

    try {
        await db.ensureUser(req.user.uid);
        const result = await db.query(
            `INSERT INTO accounts (user_id, encrypted_name, encrypted_balance, currency, type, provider_id, group_name)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id`,
            [
                req.user.uid,
                encrypted_name,
                encrypted_balance,
                currency,
                type || 'checking',
                provider_id,
                req.body.group_name || 'Personale'
            ]
        );
        res.json({ id: result.rows[0].id, message: 'Account created successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/accounts/delete
 * @desc Delete an account
 */
router.post('/delete', verifyToken, async (req, res) => {
    const { id } = req.body;

    if (!id) {
        return res.status(400).json({ error: 'Missing account ID' });
    }

    try {
        const result = await db.query(
            'DELETE FROM accounts WHERE id = $1 AND user_id = $2 RETURNING id',
            [id, req.user.uid]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'Account not found or unauthorized' });
        }

        res.json({ message: 'Account deleted successfully', id });
    } catch (error) {
        console.error('Delete Account Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
