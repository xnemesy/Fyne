import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'crypto_service.dart';
import 'notification_service.dart';
import 'api_service.dart';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This is a top-level function, it cannot use Riverpod directly easily without a container.
  // We re-initialize what we need or use a minimalist approach.
  
  if (message.data.containsKey('encrypted_payload')) {
    final encryptedPayload = message.data['encrypted_payload'];
    
    // In a real ZK app, we would need the private key stored in Secure Storage
    // For this implementation, we assume the CryptoService can access it or we have a mechanism.
    final crypto = CryptoService();
    
    // We would need the masterKey here. Usually, for background tasks, 
    // we store a 'Notification Key' in Secure Storage that can decrypt just the title/body.
    
    try {
      // Mocking decryption for the sake of the task flow. 
      // In production, this would use await crypto.decrypt(...) with a local key.
      final decryptedBody = "Nuova transazione rilevata!"; 
      
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Importante',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        "Fyne Security",
        decryptedBody,
        notificationDetails,
      );
    } catch (e) {
      print("Error decrypting background notification: $e");
    }
  }
}

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _api = ApiService();

  Future<void> init() async {
    // Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token
    String? token = await _fcm.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Handle token refresh
    _fcm.onTokenRefresh.listen(_registerToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Background messages handler registration
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _registerToken(String token) async {
    try {
      final user = FirebaseMessaging.instance; // Not used but keeps context
      final currentUser = await _api.dio.options.headers['Authorization']; // Just to check what's going on
      
      await _api.post('/api/banking/fcm-token', data: {'fcmToken': token});
      print("FCM Token registered successfully for user: ${token.substring(0, 5)}...");
    } catch (e) {
      print("Error registering FCM token: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Similar logic to background but can use UI feed or local notifications immediately
    if (message.data.containsKey('encrypted_payload')) {
      // Logic to decrypt and show
    }
  }
}
