const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../utils/db');

/**
 * @route GET /api/scheduled-transactions
 * @desc Get all scheduled transactions
 */
router.get('/', verifyToken, async (req, res) => {
    try {
        // Ensure table exists (quick fix for prototype, ideally in migration)
        await db.query(`
            CREATE TABLE IF NOT EXISTS scheduled_transactions (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
                encrypted_description TEXT NOT NULL,
                amount NUMERIC(15, 2) NOT NULL,
                currency VARCHAR(3) NOT NULL,
                frequency VARCHAR(20) NOT NULL,
                next_occurrence TIMESTAMP WITH TIME ZONE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        const result = await db.query(
            'SELECT * FROM scheduled_transactions WHERE user_id = $1 ORDER BY next_occurrence ASC',
            [req.user.uid]
        );
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/scheduled-transactions
 * @desc Create a new scheduled transaction
 */
router.post('/', verifyToken, async (req, res) => {
    const { encrypted_description, amount, currency, frequency, next_occurrence } = req.body;

    try {
        const result = await db.query(
            `INSERT INTO scheduled_transactions 
            (user_id, encrypted_description, amount, currency, frequency, next_occurrence)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id`,
            [req.user.uid, encrypted_description, amount, currency, frequency, next_occurrence]
        );
        res.json({ id: result.rows[0].id, message: 'Scheduled transaction created' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/scheduled-transactions/delete
 * @desc Delete a scheduled transaction
 */
router.post('/delete', verifyToken, async (req, res) => {
    const { id } = req.body;

    if (!id) return res.status(400).json({ error: 'Missing ID' });

    try {
        const result = await db.query(
            'DELETE FROM scheduled_transactions WHERE id = $1 AND user_id = $2 RETURNING id',
            [id, req.user.uid]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'Not found or unauthorized' });
        }
        res.json({ message: 'Deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
