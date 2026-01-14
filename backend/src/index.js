const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 8080;

const { verifyToken } = require('./middleware/auth');
const db = require('./utils/db');
const bankingRouter = require('./routes/banking');
const accountsRouter = require('./routes/accounts');
const transactionsRouter = require('./routes/transactions');

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/banking', bankingRouter);
app.use('/api/accounts', accountsRouter);
app.use('/api/transactions', transactionsRouter);

app.get('/', (req, res) => {
  res.json({
    message: 'Banking Abstraction Layer is running',
    version: '11.0.0',
    status: 'healthy'
  });
});

// Protected route example
app.get('/api/user/profile', verifyToken, (req, res) => {
  res.json({
    user: req.user,
    message: 'This is a protected profile route'
  });
});

// Real Database connection check
app.get('/health/db', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW()');
    res.json({ status: 'connected', time: result.rows[0].now });
  } catch (error) {
    console.error('Database connection error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
  // Initialize Schema on startup
  db.initSchema().catch(console.error);
});
