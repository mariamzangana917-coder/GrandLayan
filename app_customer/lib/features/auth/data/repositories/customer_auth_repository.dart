import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/customer_user.dart';

class CustomerAuthRepository {
  const CustomerAuthRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
  }) : _apiClient = apiClient,
       _storage = storage;

  final ApiClient _apiClient;
  final SecureStorageService _storage;

  Future<CustomerUser> login({
    required String login,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/customer/auth/login',
      data: {
        'login': login.trim(),
        'password': password,
        'device_name': 'Grand Layan Customer App',
      },
    );

    return _saveSessionFromResponse(response);
  }

  Future<CustomerUser> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      '/customer/auth/register',
      data: {
        'name': name.trim(),
        'phone': phone.replaceAll(' ', '').trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': 'Grand Layan Customer App',
      },
    );

    return _saveSessionFromResponse(response);
  }

  Future<CustomerUser?> restoreSession() async {
    final token = await _storage.readCustomerToken();

    if (token == null) {
      return null;
    }

    try {
      final response = await _apiClient.get('/customer/auth/me');
      final customer = _readUser(response);

      if (customer.role != 'customer') {
        await _storage.deleteCustomerToken();
        return null;
      }

      return customer;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _storage.deleteCustomerToken();
        return null;
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/customer/auth/logout');
    } finally {
      await _storage.deleteCustomerToken();
    }
  }

  Future<CustomerUser> _saveSessionFromResponse(
    Map<String, dynamic> response,
  ) async {
    final data = response['data'];

    if (data is! Map) {
      throw const ApiException(
        message: 'استجابة تسجيل الدخول غير صالحة.',
      );
    }

    final normalizedData = Map<String, dynamic>.from(data);
    final token = normalizedData['token'];

    if (token is! String || token.trim().isEmpty) {
      throw const ApiException(
        message: 'لم يتم استلام رمز تسجيل الدخول.',
      );
    }

    final customer = _readUser(response);

    if (customer.role != 'customer') {
      throw const ApiException(
        message: 'هذا الحساب غير مخصص لتطبيق الزبونة.',
        statusCode: 403,
      );
    }

    await _storage.saveCustomerToken(token.trim());
    return customer;
  }

  CustomerUser _readUser(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is! Map) {
      throw const ApiException(
        message: 'استجابة الخادم غير صالحة.',
      );
    }

    final normalizedData = Map<String, dynamic>.from(data);
    final userData = normalizedData['user'];

    if (userData is! Map) {
      throw const ApiException(
        message: 'بيانات المستخدم غير موجودة.',
      );
    }

    return CustomerUser.fromJson(
      Map<String, dynamic>.from(userData),
    );
  }
}
