const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../utils/db');

/**
 * @route GET /api/budgets
 * @desc Get all user budgets
 */
router.get('/', verifyToken, async (req, res) => {
    try {
        const result = await db.query(
            'SELECT id, category_uuid, encrypted_category_name, limit_amount, current_spent, period FROM budgets WHERE user_id = $1',
            [req.user.uid]
        );
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route PUT /api/budgets/:id
 * @desc Update budget limit (useful for transfers)
 */
router.put('/:id', verifyToken, async (req, res) => {
    const { limitAmount } = req.body;
    try {
        await db.query(
            'UPDATE budgets SET limit_amount = $1 WHERE id = $2 AND user_id = $3',
            [limitAmount, req.params.id, req.user.uid]
        );
        res.json({ message: 'Budget updated successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/budgets/transfer
 * @desc Transfer funds between two budgets
 */
router.post('/transfer', verifyToken, async (req, res) => {
    const { fromBudgetId, toBudgetId, amount } = req.body;

    // In a real app, this should be a transaction
    try {
        await db.query('BEGIN');

        // Deduct from source
        await db.query(
            'UPDATE budgets SET limit_amount = limit_amount - $1 WHERE id = $2 AND user_id = $3',
            [amount, fromBudgetId, req.user.uid]
        );

        // Add to destination
        await db.query(
            'UPDATE budgets SET limit_amount = limit_amount + $1 WHERE id = $2 AND user_id = $3',
            [amount, toBudgetId, req.user.uid]
        );

        await db.query('COMMIT');
        res.json({ message: 'Transfer successful' });
    } catch (error) {
        await db.query('ROLLBACK');
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
