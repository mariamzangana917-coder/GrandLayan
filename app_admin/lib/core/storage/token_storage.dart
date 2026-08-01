import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'admin_access_token';
  static const String _deviceTokenIdKey = 'admin_device_token_id';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveDeviceTokenId(int id) async {
    await _storage.write(key: _deviceTokenIdKey, value: id.toString());
  }

  static Future<int?> readDeviceTokenId() async {
    final value = await _storage.read(key: _deviceTokenIdKey);

    return value == null ? null : int.tryParse(value);
  }

  static Future<void> deleteDeviceTokenId() async {
    await _storage.delete(key: _deviceTokenIdKey);
  }
}
