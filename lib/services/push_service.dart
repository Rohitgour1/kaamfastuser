import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService {
  PushService._();

  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      _ready = true;
    } catch (e) {
      debugPrint('Push init skipped: $e');
    }
  }

  static Future<String?> token() async {
    try {
      await init();
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM token failed: $e');
      return null;
    }
  }

  static Stream<RemoteMessage> get foreground => FirebaseMessaging.onMessage;
  static Stream<RemoteMessage> get opened =>
      FirebaseMessaging.onMessageOpenedApp;
}
