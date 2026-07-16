import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'appointment_model.dart';

class AppointmentService {
  const AppointmentService();

  Future<AppointmentListResponse> fetchAppointments({
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      final normalizedSearch = search?.trim();

      if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
        queryParameters['search'] = normalizedSearch;
      }

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      if (fromDate != null) {
        queryParameters['from_date'] = _formatDate(fromDate);
      }

      if (toDate != null) {
        queryParameters['to_date'] = _formatDate(toDate);
      }

      final response = await ApiClient.dio.get(
        '/admin/appointments',
        queryParameters: queryParameters,
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw const AppointmentException('استجابة غير صالحة من الخادم.');
      }

      return AppointmentListResponse.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        throw const AppointmentException('انتهت جلسة تسجيل الدخول.');
      }

      if (statusCode == 403) {
        throw const AppointmentException('الحساب غير مخول لعرض المواعيد.');
      }

      if (statusCode == 422) {
        throw const AppointmentException('قيم البحث أو الفلترة غير صحيحة.');
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AppointmentException('تعذر الاتصال بالخادم.');
      }

      throw const AppointmentException('تعذر تحميل المواعيد حاليًا.');
    } on AppointmentException {
      rethrow;
    } catch (_) {
      throw const AppointmentException(
        'حدث خطأ غير متوقع أثناء تحميل المواعيد.',
      );
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

class AppointmentException implements Exception {
  const AppointmentException(this.message);

  final String message;

  @override
  String toString() => message;
}
