const express = require('express');
const router = express.Router();
const db = require('../utils/db');
const { encryptWithPublicKey } = require('../utils/crypto');
const { sendPushNotification } = require('../utils/notifications');

/**
 * Shared logic to process and save mock transactions
 */
async function processMockTransactions(userUid, accountId, transactions) {
    // 1. Get user public key and FCM token
    const result = await db.query('SELECT public_key, fcm_token FROM users WHERE uid = $1', [userUid]);
    const user = result.rows[0];

    if (!user || !user.public_key) {
        throw new Error('User not found or no public key. Ensure you have registered your public key from the app.');
    }

    // 2. Encrypt and Normalize
    const normalized = transactions.map(tx => ({
        amount: tx.amount,
        currency: tx.currency || 'EUR',
        description: encryptWithPublicKey(tx.description, user.public_key),
        counterPartyName: encryptWithPublicKey(tx.counterParty || 'Unknown', user.public_key),
        categoryUuid: tx.categoryUuid || '550e8400-e29b-41d4-a716-446655440000',
        bookingDate: tx.date || new Date().toISOString().split('T')[0],
        externalId: tx.externalId || `mock_${Date.now()}_${Math.random()}`
    }));

    // 3. Save to DB
    await db.saveTransactions(userUid, accountId, normalized);

    // 4. Send pushes if requested
    for (const tx of transactions) {
        if (tx.sendPush && user.fcm_token) {
            const payloadData = {
                type: 'TRANSACTION_REVEAL',
                title: 'Movimento Bancario',
                body: `Hai speso ${Math.abs(tx.amount)}€ presso ${tx.description}`
            };

            const encryptedPayload = encryptWithPublicKey(
                JSON.stringify(payloadData),
                user.public_key
            );

            await sendPushNotification(
                user.fcm_token,
                'Fyne Security',
                'Nuovo movimento rilevato (Cifrato)',
                { encrypted_payload: encryptedPayload }
            );
        }
    }
    return normalized.length;
}

/**
 * @route POST /api/test/mock-webhook
 * @desc Simulates a banking webhook by adding encrypted transactions directly.
 */
router.post('/mock-webhook', async (req, res) => {
    const { userUid, accountId, transactions } = req.body;

    if (!userUid || !accountId || !transactions) {
        return res.status(400).json({ error: 'userUid, accountId, and transactions are required' });
    }

    try {
        const count = await processMockTransactions(userUid, accountId, transactions);
        res.json({
            message: `Successfully seeded ${count} mock transactions.`,
            status: 'success'
        });
    } catch (error) {
        console.error('Mock Webhook Error:', error);
        res.status(error.message.includes('not found') ? 404 : 500).json({ error: error.message });
    }
});

/**
 * @route POST /api/test/seed-demo
 * @desc Quickly seeds the exact scenario requested by the user.
 */
router.post('/seed-demo', async (req, res) => {
    const { userUid, accountId, foodCategoryUuid, techCategoryUuid } = req.body;

    if (!userUid || !accountId) {
        return res.status(400).json({ error: 'userUid and accountId are required' });
    }

    const mockTransactions = [
        { description: 'Stipendio Gennaio', amount: 2500.00, categoryUuid: '00000000-0000-0000-0000-000000000000' },
        { description: 'Supermercato', amount: -65.50, categoryUuid: foodCategoryUuid },
        { description: 'Abbonamento Netflix', amount: -12.99, categoryUuid: '11111111-1111-1111-1111-111111111111' },
        { description: 'Cena Ristorante', amount: -45.00, categoryUuid: foodCategoryUuid, sendPush: true },
        { description: 'Acquisto Gadget Tech', amount: -350.00, categoryUuid: techCategoryUuid }
    ];

    try {
        const count = await processMockTransactions(userUid, accountId, mockTransactions);
        res.json({
            message: `Successfully seeded demo data for user ${userUid}.`,
            status: 'success'
        });
    } catch (error) {
        console.error('Seed Demo Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
