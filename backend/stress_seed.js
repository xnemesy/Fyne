const db = require('./src/utils/db');
const { encryptWithPublicKey } = require('./src/utils/crypto');
require('dotenv').config();

async function stressSeed() {
    try {
        const userResult = await db.query('SELECT uid, public_key FROM users WHERE public_key IS NOT NULL LIMIT 1');
        if (userResult.rows.length === 0) {
            console.error('No user with public key found.');
            process.exit(1);
        }
        const user = userResult.rows[0];
        const userUid = user.uid;
        const publicKey = user.public_key;

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

        // Ensure an account exists
        const accountResult = await db.query('SELECT id FROM accounts WHERE user_id = $1 LIMIT 1', [userUid]);
        let accountId;
        if (accountResult.rows.length === 0) {
            accountId = await db.saveAccount(userUid, {
                encryptedName: encryptWithPublicKey("Conto Stress Test", publicKey),
                encryptedBalance: encryptWithPublicKey("50000.00", publicKey),
                providerId: 'STRESS_TEST_MANUAL'
            });
        } else {
            accountId = accountResult.rows[0].id;
        }

        const transactions = [];
        const now = new Date();
        for (let i = 0; i < 200; i++) {
            const entry = realisticData[Math.floor(Math.random() * realisticData.length)];
            const date = new Date(now.getTime() - (Math.random() * 30 * 24 * 60 * 60 * 1000));

            transactions.push({
                amount: -(Math.random() * 120 + 5).toFixed(2),
                currency: 'EUR',
                description: encryptWithPublicKey(`${entry.desc} #${i}`, publicKey),
                counterPartyName: encryptWithPublicKey("Esercente stress test", publicKey),
                categoryUuid: '550e8400-e29b-41d4-a716-446655440000',
                bookingDate: date.toISOString().split('T')[0],
                externalId: `stress_manual_${Date.now()}_${i}`
            });
        }

        await db.saveTransactions(userUid, accountId, transactions);
        console.log(`✅ Success: Seeded 200 transactions for UID: ${userUid}`);
        process.exit(0);
    } catch (e) {
        console.error('Error seeding:', e);
        process.exit(1);
    }
}

stressSeed();
