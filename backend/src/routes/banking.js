const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const GoCardlessAdapter = require('../services/banking/GoCardlessAdapter');
const { encrypt } = require('../utils/crypto');
const db = require('../utils/db');

const bankingProvider = new GoCardlessAdapter();

/**
 * @route POST /api/banking/connect
 * @desc Get Open Banking auth link for a specific institution
 */
router.post('/connect', verifyToken, async (req, res) => {
    const { institutionId, redirectUrl } = req.body;

    if (!institutionId) {
        return res.status(400).json({ error: 'institutionId is required' });
    }

    try {
        // Ensure user exists in our DB
        await db.ensureUser(req.user.uid);

        const reference = `user_${req.user.uid}_${Date.now()}`;
        const authData = await bankingProvider.getAuthLink({
            institutionId,
            redirectUrl: redirectUrl || 'https://fyne.app/callback', // Default fallback
            reference
        });

        // Record the connection attempt
        await db.query(
            'INSERT INTO banking_connections (user_uid, provider, provider_requisition_id) VALUES ($1, $2, $3)',
            [req.user.uid, 'gocardless', authData.requisitionId]
        );

        res.json(authData);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/banking/sync-results
 * @desc Save transactions that have been categorized and encrypted by the client.
 */
router.post('/sync-results', verifyToken, async (req, res) => {
    const { accountId, transactions } = req.body;

    if (!accountId || !transactions) {
        return res.status(400).json({ error: 'accountId and transactions are required' });
    }

    try {
        await db.ensureUser(req.user.uid);

        // The client sends transactions with:
        // - amount (clear)
        // - description (encrypted)
        // - counterParty (encrypted)
        // - categoryUuid (anonymous UUID)
        await db.saveTransactions(req.user.uid, accountId, transactions);

        res.json({
            message: `Successfully saved ${transactions.length} private transactions and triggered budget updates.`,
            status: 'success'
        });
    } catch (error) {
        console.error('Save Sync Results Error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/budgets
 * @desc Create an anonymous budget
 */
router.post('/budgets', verifyToken, async (req, res) => {
    const { categoryUuid, encryptedName, limitAmount } = req.body;

    try {
        await db.query(
            `INSERT INTO budgets (user_id, category_uuid, encrypted_category_name, limit_amount)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (user_id, category_uuid) DO UPDATE SET
             encrypted_category_name = EXCLUDED.encrypted_category_name,
             limit_amount = EXCLUDED.limit_amount`,
            [req.user.uid, categoryUuid, encryptedName, limitAmount]
        );
        res.json({ message: 'Budget created/updated anonymously' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route GET /api/budgets
 * @desc Get current budgets status
 */
router.get('/budgets', verifyToken, async (req, res) => {
    try {
        const result = await db.query(
            'SELECT category_uuid, encrypted_category_name, limit_amount, current_spent FROM budgets WHERE user_id = $1',
            [req.user.uid]
        );
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
