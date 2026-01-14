const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const GoCardlessAdapter = require('../services/banking/GoCardlessAdapter');
const { encrypt, encryptWithPublicKey } = require('../utils/crypto');
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
 * @route GET /api/banking/fetch-raw/:accountId
 * @desc Proxy route to fetch raw transactions from the provider WITHOUT saving.
 * Used for client-side categorization and encryption.
 */
router.get('/fetch-raw/:accountId', verifyToken, async (req, res) => {
    const { accountId } = req.params;
    try {
        const transactions = await bankingProvider.getTransactions(accountId);
        res.json(transactions);
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
        console.error('Save Sync Results Error:', error.message);
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
 * @route POST /api/banking/public-key
 * @desc Register user's public key for backend-to-client encryption
 */
router.post('/public-key', verifyToken, async (req, res) => {
    const { publicKey } = req.body;
    try {
        await db.updatePublicKey(req.user.uid, publicKey);
        res.json({ message: 'Public key updated' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/banking/fcm-token
 * @desc Register user's FCM token for push notifications
 */
router.post('/fcm-token', verifyToken, async (req, res) => {
    const { fcmToken } = req.body;
    try {
        await db.ensureUser(req.user.uid);
        await db.updateFcmToken(req.user.uid, fcmToken);
        res.json({ message: 'FCM token updated' });
    } catch (error) {
        console.error('FCM Token Update Error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/banking/webhook
 * @desc Webhook handler for GoCardless/Nordigen
 */
router.post('/webhook', async (req, res) => {
    const { requisition_id, status } = req.body;
    console.log(`[Webhook] Requisition ${requisition_id} status: ${status}`);

    try {
        // 1. Get user info by requisition
        const userInfo = await db.getUserByRequisition(requisition_id);
        if (!userInfo || !userInfo.public_key) {
            console.log(`[Webhook] User not found or no public key for requisition ${requisition_id}`);
            return res.status(200).send(); // Always 200 to Apple/GoCardless
        }

        // 2. If status is LN (Linked), fetch accounts and transactions
        if (status === 'LN') {
            // Need to fetch account IDs if not already known
            const requisitionData = await bankingProvider.getRequisition(requisition_id);
            const accountIds = requisitionData.accounts || [];

            for (const accountId of accountIds) {
                await db.updateConnection(requisition_id, accountId, 'LINKED');

                // Fetch transactions
                const rawTransactions = await bankingProvider.getTransactions(accountId);

                // 3. Encrypt and Normalize
                const encryptedTransactions = rawTransactions.map(tx => ({
                    ...tx,
                    description: encryptWithPublicKey(tx.description, userInfo.public_key),
                    counterPartyName: encryptWithPublicKey(tx.counterPartyName, userInfo.public_key),
                    categoryUuid: '550e8400-e29b-41d4-a716-446655440000' // Default uncategorized
                }));

                // 4. Save to DB
                await db.saveTransactions(userInfo.uid, accountId, encryptedTransactions);
            }
        }

        res.status(200).send();
    } catch (error) {
        console.error('[Webhook Error]', error.message);
        res.status(200).send(); // Don't block provider
    }
});

module.exports = router;
