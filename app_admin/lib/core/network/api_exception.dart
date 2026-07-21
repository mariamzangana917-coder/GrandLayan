import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.validationErrors = const {},
  });

  factory ApiException.fromDio(DioException error) {
    final dynamic data = error.response?.data;

    return ApiException(
      message: data is Map
          ? (data['message']?.toString() ?? error.message ?? 'حدث خطأ غير متوقع.')
          : (error.message ?? 'حدث خطأ غير متوقع.'),
      statusCode: error.response?.statusCode,
      validationErrors: data is Map && data['errors'] is Map
          ? (data['errors'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                (value as List).map((e) => e.toString()).toList(),
              ),
            )
          : const {},
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, List<String>> validationErrors;

  String? firstErrorFor(String field) {
    final errors = validationErrors[field];

    if (errors == null || errors.isEmpty) {
      return null;
    }

    return errors.first;
  }

  @override
  String toString() => message;
}