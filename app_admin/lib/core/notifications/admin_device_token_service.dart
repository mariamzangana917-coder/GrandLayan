import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

class AdminDeviceTokenService {
  AdminDeviceTokenService._();

  static StreamSubscription<String>? _tokenSubscription;

  static Future<void> start() async {
    final token = await FirebaseMessaging.instance.getToken();

    if (token != null && token.trim().isNotEmpty) {
      await _register(token.trim());
    }

    await _tokenSubscription?.cancel();

    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      unawaited(_register(token));
    });
  }

  static Future<void> deactivate() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;

    final id = await TokenStorage.readDeviceTokenId();

    try {
      if (id != null) {
        await ApiClient.dio.delete('/admin/device-tokens/$id');
      }
    } finally {
      await TokenStorage.deleteDeviceTokenId();
    }
  }

  static Future<void> _register(String token) async {
    try {
      final response = await ApiClient.dio.post<dynamic>(
        '/admin/device-tokens',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'device_name': 'Grand Layan Admin',
          'locale': 'ar',
          'notifications_enabled': true,
        },
      );

      final root = response.data;

      if (root is Map) {
        final data = root['data'];

        if (data is Map) {
          final rawId = data['id'];
          final id = rawId is int
              ? rawId
              : int.tryParse(rawId?.toString() ?? '');

          if (id != null) {
            await TokenStorage.saveDeviceTokenId(id);
          }
        }
      }
    } catch (_) {
      // فشل تسجيل الإشعارات لا يمنع تسجيل الدخول.
    }
  }
}
