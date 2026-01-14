const admin = require('firebase-admin');
const path = require('path');

let isInitialized = false;

function initFirebase() {
    if (isInitialized) return;

    try {
        const serviceAccountPath = process.env.FIREBASE_ADMIN_SDK_PATH || path.join(__dirname, '../../firebase-admin.json');

        // Simple check if file exists
        const fs = require('fs');
        if (fs.existsSync(serviceAccountPath)) {
            const serviceAccount = require(serviceAccountPath);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            isInitialized = true;
            console.log('✅ Firebase Admin SDK initialized');
        } else {
            console.warn('⚠️ Firebase Admin SDK key not found. Push notifications will be mocked.');
        }
    } catch (error) {
        console.error('❌ Firebase Admin Initialization Error:', error);
    }
}

/**
 * Sends a push notification to a user
 */
async function sendPushNotification(fcmToken, title, body, data = {}) {
    initFirebase();

    if (!isInitialized) {
        console.log(`[MOCK PUSH] To: ${fcmToken.substring(0, 10)}... Title: ${title}, Body: ${body}`);
        return { success: true, mocked: true };
    }

    const message = {
        token: fcmToken,
        notification: {
            title,
            body
        },
        data: data,
        apns: {
            payload: {
                aps: {
                    'content-available': 1
                }
            }
        }
    };

    try {
        const response = await admin.messaging().send(message);
        console.log('Successfully sent message:', response);
        return { success: true, messageId: response };
    } catch (error) {
        console.error('Error sending message:', error);
        return { success: false, error: error.message };
    }
}

module.exports = { sendPushNotification };
