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
    pool
};
