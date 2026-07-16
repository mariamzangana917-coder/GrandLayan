import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class ApiClient {
  const ApiClient();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            responseType: ResponseType.json,
            headers: const <String, dynamic>{'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (
                  RequestOptions options,
                  RequestInterceptorHandler handler,
                ) async {
                  final String? token = await TokenStorage.readToken();

                  if (token != null && token.trim().isNotEmpty) {
                    options.headers['Authorization'] = 'Bearer ${token.trim()}';
                  } else {
                    options.headers.remove('Authorization');
                  }

                  if (options.data is FormData) {
                    options.contentType = Headers.multipartFormDataContentType;
                  } else if (options.data != null) {
                    options.contentType = Headers.jsonContentType;
                  }

                  handler.next(options);
                },
            onError:
                (DioException error, ErrorInterceptorHandler handler) async {
                  final int? statusCode = error.response?.statusCode;

                  if (statusCode == 401) {
                    await TokenStorage.deleteToken();
                  }

                  handler.next(error);
                },
          ),
        );

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.put<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.patch<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.delete<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
