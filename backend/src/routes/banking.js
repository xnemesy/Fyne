const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const GoCardlessAdapter = require('../services/banking/GoCardlessAdapter');
const MockBankingAdapter = require('../services/banking/MockBankingAdapter');
const TinkAdapter = require('../services/banking/TinkAdapter');
const { encryptWithPublicKey } = require('../utils/crypto');
const db = require('../utils/db');
const { notifyUser } = require('../utils/firebase');

const gcProvider = new GoCardlessAdapter();
const mockProvider = new MockBankingAdapter();
const tinkProvider = new TinkAdapter();

function getProviderForAccountId(accountId) {
    if (!accountId) return gcProvider;
    const normalized = String(accountId).toLowerCase();
    if (normalized.startsWith('mock_') || normalized.startsWith('sandbox')) return mockProvider;
    if (normalized.startsWith('tink_')) return tinkProvider;
    return gcProvider;
}

router.get('/institutions', verifyToken, async (req, res) => {
    const { country } = req.query;
    try {
        const mockBanks = await mockProvider.getInstitutions(country || 'IT');
        let realBanks = [];
        try {
            realBanks = await gcProvider.getInstitutions(country || 'IT');
        } catch (e) {
            console.warn("Real provider failed (likely no keys), skipping.");
        }
        const tinkEntry = {
            id: 'tink',
            name: 'Connetti Banca (Tink)',
            logo: 'https://vignette.wikia.nocookie.net/logopedia/images/4/4b/Tink_Logo_2021.png',
            bic: 'TINK'
        };
        res.json([tinkEntry, ...mockBanks, ...realBanks]);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

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

        let provider;
        if (institutionId.startsWith('SANDBOX') || institutionId.startsWith('MOCK')) {
            provider = mockProvider;
        } else if (institutionId === 'tink') {
            provider = tinkProvider;
        } else {
            provider = gcProvider;
        }

        const reference = `user_${req.user.uid}_${Date.now()}`;
        const finalRedirectUrl = institutionId === 'tink'
            ? 'https://banking-abstraction-layer-719543584184.europe-west8.run.app/api/banking/callback/tink'
            : (redirectUrl || 'https://fyne.app/callback');

        const authData = await provider.getAuthLink({
            institutionId,
            redirectUrl: finalRedirectUrl,
            reference,
            state: reference // Tink uses 'state'
        });

        // Record the connection attempt
        const providerName = provider === mockProvider ? 'mock' : (provider === tinkProvider ? 'tink' : 'gocardless');
        await db.query(
            'INSERT INTO banking_connections (user_uid, provider, provider_requisition_id) VALUES ($1, $2, $3)',
            [req.user.uid, providerName, authData.requisitionId]
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
        const provider = getProviderForAccountId(accountId);
        const transactions = await provider.getTransactions(accountId);
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
 * @route GET /api/banking/callback/tink
 * @desc Handle Tink Link callback
 */
router.get('/callback/tink', async (req, res) => {
    const { code, state } = req.query;
    try {
        // 1. Exchange code for tokens
        const tokens = await tinkProvider.exchangeCode(code);

        // 2. Get Tink User ID to map for webhooks
        const userProfile = await tinkProvider.getUserProfile(tokens.access_token);
        const tinkUserId = userProfile.id;

        // 3. Update banking_connection with tokens and Tink User ID
        // RequisitionId here matches the 'state' we sent
        await db.query(
            'UPDATE banking_connections SET access_token = $1, refresh_token = $2, provider_account_id = $3, status = $4 WHERE provider_requisition_id = $5',
            [tokens.access_token, tokens.refresh_token, tinkUserId, 'CONNECTED', state]
        );

        // 3. Trigger initial sync (optional, can be done via finalize or webhook)
        res.send('<html><body><h1>Connessione completata!</h1><p>Puoi tornare all\'app.</p><script>window.location.href="fyne://callback"</script></body></html>');
    } catch (error) {
        console.error('Tink Callback Error:', error.message);
        res.status(500).send('Errore durante la connessione con Tink');
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
 * @desc Register user's RSA public key for server-to-client encryption
 */
router.post('/public-key', verifyToken, async (req, res) => {
    const { publicKey } = req.body;
    try {
        await db.ensureUser(req.user.uid);
        await db.query('UPDATE users SET public_key = $1 WHERE uid = $2', [publicKey, req.user.uid]);
        res.json({ message: 'Public key updated' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route POST /api/banking/finalize
 * @desc Explicitly trigger account and transaction import after connection
 */
router.post('/finalize', verifyToken, async (req, res) => {
    const { requisitionId } = req.body;
    try {
        const connection = await db.query('SELECT provider FROM banking_connections WHERE provider_requisition_id = $1', [requisitionId]);
        if (connection.rows.length === 0) return res.status(404).json({ error: 'Connection not found' });

        const provider = connection.rows[0].provider === 'mock' ? mockProvider : (connection.rows[0].provider === 'tink' ? tinkProvider : gcProvider);

        let accessToken;
        if (connection.rows[0].provider === 'tink') {
            const conn = await db.query('SELECT access_token FROM banking_connections WHERE provider_requisition_id = $1', [requisitionId]);
            accessToken = conn.rows[0].access_token;
        }

        const requisitionData = await provider.getRequisition(requisitionId, accessToken);

        const user = await db.query('SELECT public_key FROM users WHERE uid = $1', [req.user.uid]);
        const publicKey = user.rows[0].public_key;

        if (!publicKey) return res.status(400).json({ error: 'Public key not registered. Cannot encrypt data.' });

        const accountIds = requisitionData.accounts || [];
        for (const accountId of accountIds) {
            // Check if account already exists
            const existing = await db.query('SELECT id FROM accounts WHERE provider_id = $1', [accountId]);
            let internalId;

            if (existing.rows.length === 0) {
                internalId = await db.saveAccount(req.user.uid, {
                    encryptedName: encryptWithPublicKey("Conto Connesso", publicKey),
                    encryptedBalance: encryptWithPublicKey("0.00", publicKey),
                    providerId: accountId
                });
            } else {
                internalId = existing.rows[0].id;
            }

            const rawTransactions = await provider.getTransactions(accountId);
            const encryptedTransactions = rawTransactions.map(tx => ({
                ...tx,
                description: encryptWithPublicKey(tx.description || "Nessuna descrizione", publicKey),
                counterPartyName: encryptWithPublicKey(tx.counterPartyName || "Ignoto", publicKey),
                categoryUuid: '550e8400-e29b-41d4-a716-446655440000'
            }));

            await db.saveTransactions(req.user.uid, internalId, encryptedTransactions);
        }

        res.json({ message: 'Sync completed', accountsSynced: accountIds.length });
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
        res.status(500).json({
            error: 'Database Error',
            details: error.message,
            db_error: error.hint || error.detail || error.message
        });
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
            return res.status(200).send();
        }

        // 2. If status linked, sync
        if (status === 'LN' || status === 'AVAILABLE') {
            console.log(`[Webhook] Linking accounts for user ${userInfo.uid}...`);
            const provider = userInfo.provider === 'mock' ? mockProvider : gcProvider;
            const requisitionData = await provider.getRequisition(requisition_id);
            const accountIds = requisitionData.accounts || [];

            for (const accountId of accountIds) {
                // Ensure Account exists in DB
                const existing = await db.query('SELECT id FROM accounts WHERE provider_id = $1', [accountId]);
                let internalId;

                if (existing.rows.length === 0) {
                    internalId = await db.saveAccount(userInfo.uid, {
                        encryptedName: encryptWithPublicKey("Conto Bancario", userInfo.public_key),
                        encryptedBalance: encryptWithPublicKey("---", userInfo.public_key),
                        providerId: accountId
                    });
                } else {
                    internalId = existing.rows[0].id;
                }

                // Fetch transactions
                const rawTransactions = await provider.getTransactions(accountId);
                const encryptedTransactions = rawTransactions.map(tx => ({
                    ...tx,
                    description: encryptWithPublicKey(tx.description || "Nessuna descrizione", userInfo.public_key),
                    counterPartyName: encryptWithPublicKey(tx.counterPartyName || "Ignoto", userInfo.public_key),
                    categoryUuid: '550e8400-e29b-41d4-a716-446655440000'
                }));

                await db.saveTransactions(userInfo.uid, internalId, encryptedTransactions);
                console.log(`[Webhook] Synced ${encryptedTransactions.length} transactions for account ${accountId}`);
            }
        }

        res.status(200).send();
    } catch (error) {
        console.error('[Webhook Error]', error.message);
        res.status(200).send();
    }
});

/**
 * @route POST /api/banking/webhook/tink
 * @desc Webhook handler for Tink
 */
router.post('/webhook/tink', async (req, res) => {
    const signature = req.headers['x-tink-signature'];
    const body = JSON.stringify(req.body);
    const TINK_WEBHOOK_SECRET = process.env.TINK_WEBHOOK_SECRET;

    if (TINK_WEBHOOK_SECRET) {
        const hmac = require('crypto').createHmac('sha256', TINK_WEBHOOK_SECRET);
        const digest = hmac.update(body).digest('hex');
        if (signature !== digest) {
            return res.status(401).send('Firma non valida');
        }
    }

    const event = req.body;
    console.log(`[Tink Webhook] Event: ${event.type} for user: ${event.userId}`);

    if (event.type === 'transactions:updated') {
        const userId = event.userId;
        try {
            // Get user's session and public key
            const conn = await db.query('SELECT refresh_token, user_uid FROM banking_connections WHERE provider_account_id = $1 OR provider_requisition_id = $1', [userId]);
            if (conn.rows.length === 0) return res.status(200).send(); // User not found

            const userUid = conn.rows[0].user_uid;
            const refreshToken = conn.rows[0].refresh_token;

            const user = await db.query('SELECT public_key FROM users WHERE uid = $1', [userUid]);
            const publicKey = user.rows[0].public_key;

            if (!publicKey) return res.status(200).send();

            // Refresh token and sync
            const { accessToken, newRefreshToken } = await tinkProvider.refreshToken(refreshToken);

            // Update token
            await db.query('UPDATE banking_connections SET refresh_token = $1, access_token = $2 WHERE user_uid = $3 AND provider = $4', [newRefreshToken, accessToken, userUid, 'tink']);

            // Sync
            const accounts = await tinkProvider.getAccounts(accessToken);
            for (const account of accounts) {
                const existing = await db.query('SELECT id FROM accounts WHERE provider_id = $1', [account.id]);
                let internalId;
                if (existing.rows.length === 0) {
                    internalId = await db.saveAccount(userUid, {
                        encryptedName: encryptWithPublicKey(account.name || "Conto Tink", publicKey),
                        encryptedBalance: encryptWithPublicKey(account.balance.toString(), publicKey),
                        providerId: account.id
                    });
                } else {
                    internalId = existing.rows[0].id;
                }

                const rawTransactions = await tinkProvider.getTransactions(accessToken, { accountId: account.id });
                const encryptedTransactions = rawTransactions.map(tx => ({
                    ...tx,
                    description: encryptWithPublicKey(tx.description || "Nessuna descrizione", publicKey),
                    counterPartyName: encryptWithPublicKey(tx.counterPartyName || "Ignoto", publicKey),
                    categoryUuid: '550e8400-e29b-41d4-a716-446655440000'
                }));

                await db.saveTransactions(userUid, internalId, encryptedTransactions);
            }

            console.log(`[Tink Webhook] Completed sync for ${userUid}. Notifying device...`);
            const session = await db.getUserBankSession(userUid);
            await notifyUser(session.fcm_token, { type: 'SYNC_READY' });

        } catch (e) {
            console.error('[Tink Webhook Sync Error]', e.message);
        }
    }

    res.status(200).send('OK');
});

/**
 * @route POST /api/banking/debug/seed-load-test
 * @desc Generate 200 historical transactions for RSA performance stress testing
 */
router.post('/debug/seed-load-test', verifyToken, async (req, res) => {
    try {
        const user = await db.query('SELECT public_key FROM users WHERE uid = $1', [req.user.uid]);
        const publicKey = user.rows[0].public_key;
        if (!publicKey) return res.status(400).json({ error: 'Public key missing' });

        const accounts = await db.query('SELECT id FROM accounts WHERE user_id = $1 LIMIT 1', [req.user.uid]);
        let accountId;
        if (accounts.rows.length === 0) {
            accountId = await db.saveAccount(req.user.uid, {
                encryptedName: encryptWithPublicKey("Conto Stress Test", publicKey),
                encryptedBalance: encryptWithPublicKey("25000.00", publicKey),
                providerId: 'STRESS_TEST_ACC'
            });
        } else {
            accountId = accounts.rows[0].id;
        }

        const realisticData = [
            { desc: "Esselunga Milano", cat: "Alimentari" },
            { desc: "Lidl Roma", cat: "Alimentari" },
            { desc: "Carrefour Express", cat: "Alimentari" },
            { desc: "Netflix Monthly", cat: "Abbonamenti" },
            { desc: "Spotify Premium", cat: "Abbonamenti" },
            { desc: "Disney Plus", cat: "Abbonamenti" },
            { desc: "Virgin Active City", cat: "Wellness" },
            { desc: "Farmacia Centrale", cat: "Wellness" },
            { desc: "Amazon IT Order", cat: "Shopping" },
            { desc: "Zalando Reso", cat: "Shopping" },
            { desc: "Benzina Eni", cat: "Trasporti" },
            { desc: "Biglietto Trenitalia", cat: "Trasporti" },
            { desc: "Uber Black", cat: "Trasporti" },
            { desc: "McDonalds Drive", cat: "Fast Food" },
            { desc: "Poke House", cat: "Fast Food" },
            { desc: "Scommesse Snai", cat: "Vizi" },
            { desc: "Tabacchi n.12", cat: "Vizi" }
        ];

        const transactions = [];
        const now = new Date();
        for (let i = 0; i < 200; i++) {
            const entry = realisticData[Math.floor(Math.random() * realisticData.length)];
            // Spread over last 30 days
            const date = new Date(now.getTime() - (Math.random() * 30 * 24 * 60 * 60 * 1000));

            transactions.push({
                amount: -(Math.random() * 150 + 2).toFixed(2),
                currency: 'EUR',
                description: encryptWithPublicKey(`${entry.desc} #${i}`, publicKey),
                counterPartyName: encryptWithPublicKey("Esercente Verificato", publicKey),
                categoryUuid: '550e8400-e29b-41d4-a716-446655440000', // Default, local categorizer will handle it
                bookingDate: date.toISOString().split('T')[0],
                externalId: `stress_test_${Date.now()}_${i}`
            });
        }

        await db.saveTransactions(req.user.uid, accountId, transactions);
        console.log(`✅ Stress Test Seeded: 200 transactions for ${req.user.uid}`);
        res.json({ message: 'Stress test data (200 TX) seeded successfully!', count: 200 });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
