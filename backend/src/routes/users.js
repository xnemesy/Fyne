const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../utils/db');

/**
 * @route POST /api/users/init
 * @desc Initialize user profile and save local Public Key
 */
router.post('/init', verifyToken, async (req, res) => {
    const { publicKey, email } = req.body;

    if (!publicKey) {
        return res.status(400).json({ error: 'Public Key is required for Zero-Knowledge sync' });
    }

    try {
        await db.ensureUser(req.user.uid);

        // Update public key and email if provided
        await db.query(
            'UPDATE users SET public_key = $1, email = $2 WHERE uid = $3',
            [publicKey, email || null, req.user.uid]
        );

        res.json({ message: 'User initialized successfully', uid: req.user.uid });
    } catch (error) {
        console.error('User Init Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
