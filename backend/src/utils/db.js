const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

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
        const schemaPath = path.join(__dirname, '../models/schema.sql');
        const sql = fs.readFileSync(schemaPath, 'utf8');
        try {
            await pool.query(sql);
            console.log('✅ Database schema initialized');
        } catch (err) {
            console.error('❌ Error initializing schema:', err);
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
            `SELECT u.uid, u.public_key, c.provider_account_id 
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

    pool
};
