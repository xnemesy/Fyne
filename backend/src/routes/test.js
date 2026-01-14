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

    if (!user) {
        throw new Error('User not found in database.');
    }

    // 2. Encrypt and Normalize (Skip encryption if no public key)
    const normalized = transactions.map(tx => ({
        amount: tx.amount,
        currency: tx.currency || 'EUR',
        description: user && user.public_key ? encryptWithPublicKey(tx.description, user.public_key) : tx.description,
        counterPartyName: user && user.public_key ? encryptWithPublicKey(tx.counterParty || 'Unknown', user.public_key) : (tx.counterParty || 'Unknown'),
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

            if (user.public_key) {
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
            } else {
                await sendPushNotification(
                    user.fcm_token,
                    payloadData.title,
                    payloadData.body,
                    { type: payloadData.type }
                );
            }
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
        console.error('Mock Webhook Error:', error.message);
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
        console.error('Seed Demo Error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

router.get('/debug/:uid', async (req, res) => {
    try {
        const user = await db.query('SELECT uid, public_key, fcm_token FROM users WHERE uid = $1', [req.params.uid]);
        const accounts = await db.query('SELECT id, encrypted_name FROM accounts WHERE user_id = $1', [req.params.uid]);
        const txCols = await db.query("SELECT column_name FROM information_schema.columns WHERE table_name='transactions'");
        const accCols = await db.query("SELECT column_name FROM information_schema.columns WHERE table_name='accounts'");
        res.json({
            user: user.rows[0],
            accounts: accounts.rows,
            transaction_columns: txCols.rows.map(r => r.column_name),
            account_columns: accCols.rows.map(r => r.column_name)
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

router.get('/reset-schema', async (req, res) => {
    try {
        await db.query('DROP TABLE IF EXISTS transactions CASCADE');
        await db.query('DROP TABLE IF EXISTS budgets CASCADE');
        await db.initSchema();
        res.json({ message: 'Schema reset successfully' });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

router.get('/simulate-auth', (req, res) => {
    const { req: requisitionId, redirect } = req.query;
    res.send(`
        <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; background: #000; color: white; margin: 0; padding: 20px; text-align: center; }
                    .card { background: #1a1a1a; padding: 30px; border-radius: 24px; box-shadow: 0 20px 40px rgba(0,0,0,0.5); max-width: 400px; width: 100%; border: 1px solid #333; }
                    .logo { font-size: 40px; margin-bottom: 20px; }
                    h2 { margin: 0 0 10px 0; font-size: 24px; }
                    p { color: #888; margin-bottom: 30px; line-height: 1.5; }
                    .btn { background: #4A6741; color: white; padding: 16px 32px; border-radius: 14px; text-decoration: none; font-weight: bold; display: inline-block; transition: transform 0.2s; }
                    .btn:active { transform: scale(0.95); }
                </style>
            </head>
            <body>
                <div class="card">
                    <div class="logo">⚡️</div>
                    <h2>Fyne Sandbox Bank</h2>
                    <p>Questa è una simulazione sicura. Autorizzando, permetterai a Fyne di importare i tuoi movimenti (fittizi) in modo cifrato.</p>
                    <button id="authBtn" class="btn">AUTORIZZA E CONTINUA</button>
                </div>

                <script>
                    document.getElementById('authBtn').onclick = function() {
                        this.innerText = 'Sincronizzazione...';
                        this.disabled = true;
                        
                        // 1. Trigger the Webhook locally to simulate the bank's callback
                        fetch('/api/banking/webhook', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                requisition_id: '${requisitionId}',
                                status: 'LN'
                            })
                        }).then(() => {
                            // 2. Redirect back to the app
                            window.location.href = '${redirect}';
                        }).catch(err => {
                            alert('Errore di connessione: ' + err);
                            window.location.href = '${redirect}';
                        });
                    };
                </script>
            </body>
        </html>
    `);
});

module.exports = router;
