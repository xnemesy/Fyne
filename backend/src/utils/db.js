const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST || '10.80.0.3', // Private IP of Cloud SQL
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || 'postgres',
    port: 5432,
});

module.exports = {
    query: (text, params) => pool.query(text, params),

    /**
     * Initializes the database schema
     */
    initSchema: async () => {
        try {
            console.log('--- Starting Database Migration/Initialization ---');

            // 1. Ensure extensions for UUID generation
            try {
                await pool.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
                console.log('✅ pgcrypto extension verified');
            } catch (e) {
                console.warn('⚠️ Could not ensure pgcrypto (might lack superuser), continuing...', e.message);
            }
            // 2. Users table (Uniform ID: uid VARCHAR 128 as PK)
            await pool.query(`
                CREATE TABLE IF NOT EXISTS users (
                    uid VARCHAR(128) PRIMARY KEY,
                    fcm_token TEXT,
                    public_key TEXT,
                    email TEXT,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                )
            `);
            console.log('✅ Users table verified');

            // 2.1 Migration for email in users
            try {
                const checkCol = await pool.query(
                    "SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='email'"
                );
                if (checkCol.rows.length === 0) {
                    await pool.query("ALTER TABLE users ADD COLUMN email TEXT");
                    console.log('✅ Added column email to users');
                }
            } catch (e) {
                console.error('❌ Error migraton email for users:', e.message);
            }

            // 3. Banking Connections table
            await pool.query(`
                CREATE TABLE IF NOT EXISTS banking_connections (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
                    provider VARCHAR(50),
                    provider_requisition_id TEXT UNIQUE,
                    provider_account_id TEXT,
                    status TEXT,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                )
            `);
            console.log('✅ Banking Connections table verified');

            const connColumns = [
                { name: 'refresh_token', type: 'TEXT' },
                { name: 'access_token', type: 'TEXT' }
            ];

            for (const col of connColumns) {
                try {
                    const checkCol = await pool.query(
                        "SELECT 1 FROM information_schema.columns WHERE table_name='banking_connections' AND column_name=$1",
                        [col.name]
                    );
                    if (checkCol.rows.length === 0) {
                        await pool.query(`ALTER TABLE banking_connections ADD COLUMN ${col.name} ${col.type}`);
                        console.log(`✅ Added column ${col.name} to banking_connections`);
                    }
                } catch (e) {
                    console.error(`❌ Error verifying column ${col.name} in banking_connections:`, e.message);
                }
            }

            // 4. Accounts table
            await pool.query(`
                CREATE TABLE IF NOT EXISTS accounts (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
                    encrypted_name TEXT NOT NULL,
                    encrypted_balance TEXT NOT NULL,
                    currency VARCHAR(3) NOT NULL,
                    type VARCHAR(20) DEFAULT 'checking',
                    provider_id VARCHAR(50),
                    group_name VARCHAR(50) DEFAULT 'Personale',
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                )
            `);
            console.log('✅ Accounts table verified');

            // 4.1 Migration for group_name
            try {
                const checkCol = await pool.query(
                    "SELECT 1 FROM information_schema.columns WHERE table_name='accounts' AND column_name='group_name'"
                );
                if (checkCol.rows.length === 0) {
                    await pool.query("ALTER TABLE accounts ADD COLUMN group_name VARCHAR(50) DEFAULT 'Personale'");
                    console.log('✅ Added column group_name to accounts');
                }
            } catch (e) {
                console.error('❌ Error migraton group_name for accounts:', e.message);
            }

            // 5. Transactions table verified
            await pool.query(`
                CREATE TABLE IF NOT EXISTS transactions (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
                    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
                    amount NUMERIC(15, 2) NOT NULL,
                    currency VARCHAR(3) NOT NULL,
                    encrypted_description TEXT NOT NULL,
                    encrypted_counter_party TEXT,
                    category_uuid UUID NOT NULL,
                    booking_date DATE NOT NULL,
                    external_id VARCHAR(255),
                    UNIQUE(account_id, external_id)
                )
            `);

            const txColumns = [
                { name: 'user_id', type: 'VARCHAR(128) REFERENCES users(uid)' },
                { name: 'encrypted_description', type: 'TEXT' },
                { name: 'encrypted_counter_party', type: 'TEXT' },
                { name: 'category_uuid', type: 'UUID' }
            ];

            for (const col of txColumns) {
                try {
                    const checkCol = await pool.query(
                        "SELECT 1 FROM information_schema.columns WHERE table_name='transactions' AND column_name=$1",
                        [col.name]
                    );
                    if (checkCol.rows.length === 0) {
                        // If user_uid exists but user_id doesn't, rename it
                        if (col.name === 'user_id') {
                            const checkTables = ['transactions', 'banking_connections'];
                            for (const t of checkTables) {
                                const checkUid = await pool.query(
                                    "SELECT 1 FROM information_schema.columns WHERE table_name=$1 AND column_name='user_uid'",
                                    [t]
                                );
                                if (checkUid.rows.length > 0) {
                                    await pool.query(`ALTER TABLE ${t} RENAME COLUMN user_uid TO user_id`);
                                    console.log(`✅ Renamed user_uid to user_id in ${t}`);
                                }
                            }
                            continue;
                        }
                        await pool.query(`ALTER TABLE transactions ADD COLUMN ${col.name} ${col.type}`);
                        console.log(`✅ Added column ${col.name} to transactions`);
                    }
                } catch (e) {
                    console.error(`❌ Error verifying column ${col.name} in transactions:`, e.message);
                }
            }

            // 6. Budgets table
            await pool.query(`
                CREATE TABLE IF NOT EXISTS budgets (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
                    category_uuid UUID NOT NULL,
                    encrypted_category_name TEXT NOT NULL,
                    limit_amount NUMERIC(15, 2) NOT NULL,
                    current_spent NUMERIC(15, 2) DEFAULT 0,
                    period VARCHAR(20) DEFAULT 'MONTHLY',
                    UNIQUE(user_id, category_uuid)
                )
            `);
            console.log('✅ Budgets table verified');

            console.log('--- Database Migration Completed ---');
        } catch (err) {
            console.error('❌ CRITICAL DB MIGRATION ERROR:', err.message);
            throw err;
        }
    },

    /**
     * Ensures a user exists in our DB
     */
    ensureUser: async (uid) => {
        await pool.query(
            'INSERT INTO users (uid) VALUES ($1) ON CONFLICT (uid) DO NOTHING',
            [uid]
        );
    },

    /**
     * Save an account
     */
    saveAccount: async (userUid, { encryptedName, encryptedBalance, providerId }) => {
        const result = await pool.query(
            'INSERT INTO accounts (user_id, encrypted_name, encrypted_balance, provider_id) VALUES ($1, $2, $3, $4) RETURNING id',
            [userUid, encryptedName, encryptedBalance, providerId]
        );
        return result.rows[0].id;
    },

    /**
     * Bulk save normalized and encrypted transactions
     */
    saveTransactions: async (userUid, accountId, transactions) => {
        const query = `
        INSERT INTO transactions (
          account_id, user_id, amount, currency, 
          encrypted_description, encrypted_counter_party, category_uuid, 
          booking_date, external_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (account_id, external_id) DO NOTHING
      `;

        for (const tx of transactions) {
            await pool.query(query, [
                accountId,
                userUid,
                tx.amount,
                tx.currency,
                tx.description,
                tx.counterPartyName,
                tx.categoryUuid,
                tx.bookingDate,
                tx.externalId
            ]);
        }
    },

    /**
     * Updates user's public key for backend encryption
     */
    updatePublicKey: async (uid, publicKey) => {
        await pool.query(
            'UPDATE users SET public_key = $1 WHERE uid = $2',
            [publicKey, uid]
        );
    },

    /**
     * Gets user and connection info by requisition ID (for webhooks)
     */
    getUserByRequisition: async (requisitionId) => {
        const result = await pool.query(
            `SELECT u.uid, u.public_key, c.provider 
             FROM users u 
             JOIN banking_connections c ON u.uid = c.user_uid 
             WHERE c.provider_requisition_id = $1`,
            [requisitionId]
        );
        return result.rows[0];
    },

    /**
     * Updates connection status and account ID
     */
    updateConnection: async (requisitionId, accountId, status) => {
        await pool.query(
            'UPDATE banking_connections SET provider_account_id = $1, status = $2 WHERE provider_requisition_id = $3',
            [accountId, status, requisitionId]
        );
    },

    /**
     * Updates user's FCM token
     */
    updateFcmToken: async (uid, fcmToken) => {
        await pool.query(
            'UPDATE users SET fcm_token = $1 WHERE uid = $2',
            [fcmToken, uid]
        );
    },

    /**
     * Gets user and connection info by user UID
     */
    getUserBankSession: async (userUid) => {
        const result = await pool.query(
            `SELECT u.uid, u.public_key, u.fcm_token, c.refresh_token, c.provider 
             FROM users u 
             JOIN banking_connections c ON u.uid = c.user_uid 
             WHERE u.uid = $1`,
            [userUid]
        );
        return result.rows[0];
    },

    pool
};
