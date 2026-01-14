const admin = require('firebase-admin');

// In production, Firebase Admin uses the default service account automatically
// if running on GCP (Cloud Run, Functions, etc.)
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.applicationDefault()
    });
}

const auth = admin.auth();
const messaging = admin.messaging();

async function notifyUser(fcmToken, data) {
    if (!fcmToken) return;
    try {
        await messaging.send({
            token: fcmToken,
            data: data,
            notification: {
                title: 'Aggiornamento Bancario',
                body: 'Nuove transazioni sincronizzate in modo sicuro.'
            },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true // For silent sync
                    }
                }
            }
        });
    } catch (e) {
        console.error('Error sending FCM notification:', e.message);
    }
}

module.exports = { auth, notifyUser };
