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
 * @route GET /api/banking/sync/:accountId
 * @desc Fetch, normalize, encrypt and save transactions
 */
router.get('/sync/:accountId', verifyToken, async (req, res) => {
    const { accountId } = req.params;
    const masterKey = process.env.ENCRYPTION_MASTER_KEY; // Should come from client in a real zero-knowledge flow

    if (!masterKey) {
        return res.status(500).json({ error: 'Server encryption key not configured' });
    }

    try {
        await db.ensureUser(req.user.uid);

        const transactions = await bankingProvider.getTransactions(accountId);

        // Normalize, Encrypt
        const processedTransactions = transactions.map(tx => {
            // Encrypt sensitive fields (description and counterPartyName)
            const encryptedDescription = encrypt(tx.description, masterKey);
            const encryptedCounterParty = encrypt(tx.counterPartyName, masterKey);

            return {
                ...tx,
                description: encryptedDescription,
                counterPartyName: encryptedCounterParty,
                isEncrypted: true
            };
        });

        // Persistence in PostgreSQL
        await db.saveTransactions(req.user.uid, accountId, processedTransactions);

        res.json({
            message: `Synced and encrypted ${processedTransactions.length} transactions`,
            count: processedTransactions.length
        });

    } catch (error) {
        console.error('Sync Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
