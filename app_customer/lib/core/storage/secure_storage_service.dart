import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const String customerTokenKey = 'customer_access_token';
  static const String customerDeviceTokenIdKey = 'customer_device_token_id';

  final FlutterSecureStorage _storage;

  Future<void> saveCustomerToken(String token) async {
    await _storage.write(key: customerTokenKey, value: token);
  }

  Future<String?> readCustomerToken() async {
    final token = await _storage.read(key: customerTokenKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  Future<void> deleteCustomerToken() async {
    await _storage.delete(key: customerTokenKey);
  }

  Future<void> saveCustomerDeviceTokenId(int id) async {
    await _storage.write(key: customerDeviceTokenIdKey, value: id.toString());
  }

  Future<int?> readCustomerDeviceTokenId() async {
    final value = await _storage.read(key: customerDeviceTokenIdKey);

    return value == null ? null : int.tryParse(value);
  }

  Future<void> deleteCustomerDeviceTokenId() async {
    await _storage.delete(key: customerDeviceTokenIdKey);
  }
}
