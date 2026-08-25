import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required SecureStorageService storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final token = await _storage.readCustomerToken();

              if (token != null && token.trim().isNotEmpty) {
                options.headers['Authorization'] = 'Bearer ${token.trim()}';
              } else {
                options.headers.remove('Authorization');
              }

              handler.next(options);
            },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final statusCode = error.response?.statusCode;

          if (statusCode == 401 || statusCode == 403) {
            await _storage.deleteCustomerToken();
          }

          handler.next(error);
        },
      ),
    );
  }

  final SecureStorageService _storage;
  late final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );

      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.data == null || response.data == '') {
        return <String, dynamic>{};
      }

      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Map<String, dynamic> _normalizeResponse(dynamic responseData) {
    if (responseData == null) {
      return <String, dynamic>{};
    }

    if (responseData is Map<String, dynamic>) {
      return responseData;
    }

    if (responseData is Map) {
      return Map<String, dynamic>.from(responseData);
    }

    throw const ApiException(message: 'استجابة الخادم غير صالحة.');
  }

  ApiException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    final responseData = error.response?.data;

    String? serverMessage;

    if (responseData is Map) {
      final normalizedData = Map<String, dynamic>.from(responseData);

      final message = normalizedData['message'];

      if (message is String && message.trim().isNotEmpty) {
        serverMessage = message.trim();
      }

      final errors = normalizedData['errors'];

      if (serverMessage == null && errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          serverMessage = firstError.first.toString();
        } else if (firstError != null) {
          serverMessage = firstError.toString();
        }
      }
    }

    final message = switch (error.type) {
      DioExceptionType.connectionTimeout => 'انتهت مهلة الاتصال بالخادم.',
      DioExceptionType.sendTimeout => 'انتهت مهلة إرسال البيانات.',
      DioExceptionType.receiveTimeout => 'انتهت مهلة استلام البيانات.',
      DioExceptionType.connectionError => 'تعذر الاتصال بالخادم.',
      DioExceptionType.badCertificate => 'تعذر التحقق من أمان الاتصال.',
      DioExceptionType.cancel => 'تم إلغاء الطلب.',
      _ => serverMessage ?? 'حدث خطأ أثناء الاتصال بالخادم.',
    };

    return ApiException(message: message, statusCode: statusCode);
  }
}
