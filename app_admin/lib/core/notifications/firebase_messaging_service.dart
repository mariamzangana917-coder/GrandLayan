import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM notification opened: ${message.messageId}');
    });
  }
}
