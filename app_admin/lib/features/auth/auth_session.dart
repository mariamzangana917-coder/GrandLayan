import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/notifications/admin_device_token_service.dart';
import '../../core/storage/token_storage.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthSession extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;
  String? _errorMessage;
  Map<String, dynamic>? _manager;

  AuthStatus get status => _status;

  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get manager => _manager;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// يتحقق من الجلسة المحفوظة عند تشغيل التطبيق.
  ///
  /// مهم:
  /// - 401 أو 403: الجلسة غير صالحة، نحذف التوكن.
  /// - توقف Laravel أو انقطاع الإنترنت: نبقي التوكن
  ///   ونسمح بفتح التطبيق بدل إرجاع المديرة لتسجيل الدخول.
  Future<void> initialize() async {
    _status = AuthStatus.checking;
    _errorMessage = null;
    notifyListeners();

    final token = await TokenStorage.readToken();

    if (token == null || token.trim().isEmpty) {
      _manager = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final response = await ApiClient.dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      _manager = _extractUser(response.data);
      _errorMessage = null;
      _status = AuthStatus.authenticated;

      await AdminDeviceTokenService.start();
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        // فقط هنا نحذف التوكن؛ لأن الخادم أكد أن الجلسة
        // غير صالحة أو الحساب غير مخول.
        await TokenStorage.deleteToken();

        _manager = null;
        _errorMessage = statusCode == 401
            ? 'انتهت جلسة تسجيل الدخول.'
            : 'هذا الحساب غير مصرح له بالدخول.';
        _status = AuthStatus.unauthenticated;
      } else {
        // الخادم متوقف، الإنترنت مقطوع، timeout أو خطأ 500.
        // التوكن يبقى محفوظًا ولا نرجع لشاشة تسجيل الدخول.
        _errorMessage = _readSessionErrorMessage(error);
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      // خطأ محلي أو استجابة غير متوقعة:
      // لا نحذف جلسة صحيحة بسبب مشكلة مؤقتة.
      _errorMessage = 'تعذر التحقق من الجلسة حاليًا، لكن تسجيل الدخول محفوظ.';
      _status = AuthStatus.authenticated;
    }

    notifyListeners();
  }

  Future<bool> login({required String login, required String password}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'login': login.trim(),
          'password': password,
          'device_name': 'Grand Layan Admin',
        },
      );

      final token = _extractToken(response.data);

      if (token == null || token.trim().isEmpty) {
        _errorMessage = 'الخادم لم يُرجع رمز تسجيل الدخول.';
        notifyListeners();
        return false;
      }

      await TokenStorage.saveToken(token);
      await AdminDeviceTokenService.start();

      _manager = _extractUser(response.data);
      _status = AuthStatus.authenticated;
      _errorMessage = null;

      notifyListeners();
      return true;
    } on DioException catch (error) {
      _errorMessage = _readLoginErrorMessage(error);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'حدث خطأ غير متوقع أثناء تسجيل الدخول.';
      notifyListeners();
      return false;
    }
  }

  /// إعادة التحقق من الجلسة، مثلًا بعد رجوع Laravel للعمل.
  Future<void> retrySessionCheck() async {
    await initialize();
  }

  Future<void> logout() async {
    final token = await TokenStorage.readToken();

    await AdminDeviceTokenService.deactivate();

    if (token != null && token.trim().isNotEmpty) {
      try {
        await ApiClient.dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {
        // تسجيل الخروج المحلي يجب أن ينجح حتى لو الخادم متوقف.
      }
    }

    await TokenStorage.deleteToken();

    _manager = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  String? _extractToken(dynamic responseData) {
    if (responseData is! Map) {
      return null;
    }

    final root = Map<String, dynamic>.from(responseData);

    final directToken =
        root['token'] ?? root['access_token'] ?? root['plain_text_token'];

    if (directToken != null) {
      return directToken.toString();
    }

    final data = root['data'];

    if (data is Map) {
      final mappedData = Map<String, dynamic>.from(data);

      final nestedToken =
          mappedData['token'] ??
          mappedData['access_token'] ??
          mappedData['plain_text_token'];

      return nestedToken?.toString();
    }

    return null;
  }

  Map<String, dynamic>? _extractUser(dynamic responseData) {
    if (responseData is! Map) {
      return null;
    }

    final root = Map<String, dynamic>.from(responseData);

    final directUser = root['user'] ?? root['manager'];

    if (directUser is Map) {
      return Map<String, dynamic>.from(directUser);
    }

    final data = root['data'];

    if (data is Map) {
      final mappedData = Map<String, dynamic>.from(data);

      final nestedUser = mappedData['user'] ?? mappedData['manager'];

      if (nestedUser is Map) {
        return Map<String, dynamic>.from(nestedUser);
      }

      if (mappedData.containsKey('id') && mappedData.containsKey('name')) {
        return mappedData;
      }
    }

    return null;
  }

  String _readLoginErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _extractServerMessage(error);

    if (serverMessage != null) {
      return serverMessage;
    }

    if (statusCode == 401) {
      return 'البريد الإلكتروني أو رقم الهاتف أو كلمة المرور غير صحيحة.';
    }

    if (statusCode == 403) {
      return 'هذا الحساب غير مصرح له بالدخول إلى تطبيق الإدارة.';
    }

    if (_isTimeout(error)) {
      return 'انتهت مهلة الاتصال بالخادم.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'تعذر الاتصال بالخادم. تأكدي أن Laravel يعمل.';
    }

    return 'تعذر تسجيل الدخول حاليًا.';
  }

  String _readSessionErrorMessage(DioException error) {
    if (_isTimeout(error)) {
      return 'انتهت مهلة الاتصال بالخادم. تسجيل الدخول ما زال محفوظًا.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'تعذر الاتصال بالخادم. تسجيل الدخول ما زال محفوظًا.';
    }

    final statusCode = error.response?.statusCode;

    if (statusCode != null && statusCode >= 500) {
      return 'الخادم يواجه مشكلة مؤقتة. تسجيل الدخول ما زال محفوظًا.';
    }

    return 'تعذر التحقق من الجلسة حاليًا، لكن تسجيل الدخول محفوظ.';
  }

  String? _extractServerMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is! Map) {
      return null;
    }

    final data = Map<String, dynamic>.from(responseData);

    final message = data['message'];

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final errors = data['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }

      return firstError.toString();
    }

    return null;
  }

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }
}
