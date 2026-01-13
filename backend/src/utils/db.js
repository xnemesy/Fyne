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
          account_id, user_uid, external_id, amount, currency, 
          description, counter_party, booking_date, status, is_encrypted
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        ON CONFLICT (account_id, external_id) DO UPDATE SET
          amount = EXCLUDED.amount,
          status = EXCLUDED.status,
          description = EXCLUDED.description
      `;

        for (const tx of transactions) {
            await pool.query(query, [
                accountId,
                userUid,
                tx.externalId,
                tx.amount,
                tx.currency,
                tx.description,
                tx.counterPartyName,
                tx.bookingDate,
                tx.status,
                tx.isEncrypted
            ]);
        }
    },

    pool
};
