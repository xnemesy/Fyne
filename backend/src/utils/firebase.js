const admin = require('firebase-admin');

// In production, Firebase Admin uses the default service account automatically
// if running on GCP (Cloud Run, Functions, etc.)
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.applicationDefault()
    });
}

const auth = admin.auth();

module.exports = { auth };
