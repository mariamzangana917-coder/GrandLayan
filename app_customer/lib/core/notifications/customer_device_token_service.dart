import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

class CustomerDeviceTokenService {
  CustomerDeviceTokenService({
    required ApiClient apiClient,
    required SecureStorageService storage,
  }) : _apiClient = apiClient,
       _storage = storage;

  final ApiClient _apiClient;
  final SecureStorageService _storage;

  StreamSubscription<String>? _tokenSubscription;

  Future<void> start() async {
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

  Future<void> deactivate() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;

    final id = await _storage.readCustomerDeviceTokenId();

    try {
      if (id != null) {
        await _apiClient.delete('/customer/device-tokens/$id');
      }
    } finally {
      await _storage.deleteCustomerDeviceTokenId();
    }
  }

  Future<void> _register(String token) async {
    try {
      final response = await _apiClient.post(
        '/customer/device-tokens',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'device_name': 'Grand Layan Customer',
          'locale': 'ar',
          'notifications_enabled': true,
        },
      );

      final data = response['data'];

      if (data is Map) {
        final rawId = data['id'];
        final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

        if (id != null) {
          await _storage.saveCustomerDeviceTokenId(id);
        }
      }
    } catch (_) {
      // فشل تسجيل الإشعارات لا يمنع تسجيل الدخول.
    }
  }
}
