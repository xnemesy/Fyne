const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../utils/db');
const { auth } = require('../utils/firebase');

/**
 * Apple Sign-In Config (Used by Firebase Console, but kept here for reference)
 * teamId: 'ZLART575Y4'
 * bundleId: 'com.fyne.signinwithapple'
 * keyId: 'WJQCCYZCA22'
 */

/**
 * @route POST /api/auth/signin
 * @desc Verify Apple/Google ID Token and ensure user exists in DB
 */
router.post('/signin', verifyToken, async (req, res) => {
    try {
        // req.user is already populated by verifyToken middleware (decoded Firebase token)
        const { uid, email, name, picture } = req.user;

        // Ensure user exists in our PostgreSQL database
        await db.ensureUser(uid);

        // Optional: Update email if it changed
        if (email) {
            await db.query('UPDATE users SET email = $1 WHERE uid = $2', [email, uid]);
        }

        res.json({
            message: 'Successfully signed in',
            user: {
                uid: uid,
                email: email,
                displayName: name || 'Fyne User',
                photoURL: picture
            }
        });
    } catch (error) {
        console.error('Auth Signin error:', error);
        res.status(500).json({ error: 'Internal server error during authentication' });
    }
});

module.exports = router;
