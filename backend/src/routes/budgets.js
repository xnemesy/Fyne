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

/**
 * @route POST /api/budgets/delete
 * @desc Delete a budget
 */
router.post('/delete', verifyToken, async (req, res) => {
    const { id } = req.body;

    if (!id) {
        return res.status(400).json({ error: 'Missing budget ID' });
    }

    try {
        const result = await db.query(
            'DELETE FROM budgets WHERE id = $1 AND user_id = $2 RETURNING id',
            [id, req.user.uid]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'Budget not found or unauthorized' });
        }

        res.json({ message: 'Budget deleted successfully', id });
    } catch (error) {
        console.error('Delete Budget Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
