import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'appointment_details_model.dart';
import 'appointment_service.dart';

class AppointmentDetailsService {
  const AppointmentDetailsService();

  Future<AppointmentDetails> fetchDetails(int appointmentId) async {
    try {
      final response = await ApiClient.dio.get(
        '/admin/appointments/$appointmentId',
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw const AppointmentException('استجابة غير صالحة من الخادم.');
      }

      final root = Map<String, dynamic>.from(responseData);

      final data = root['data'];

      if (data is! Map) {
        throw const AppointmentException('تفاصيل الموعد غير موجودة.');
      }

      return AppointmentDetails.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        throw const AppointmentException('انتهت جلسة تسجيل الدخول.');
      }

      if (statusCode == 403) {
        throw const AppointmentException('الحساب غير مخول لعرض تفاصيل الموعد.');
      }

      if (statusCode == 404) {
        throw const AppointmentException('الموعد غير موجود أو تم حذفه.');
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AppointmentException('تعذر الاتصال بالخادم.');
      }

      throw const AppointmentException('تعذر تحميل تفاصيل الموعد حاليًا.');
    } on AppointmentException {
      rethrow;
    } catch (_) {
      throw const AppointmentException(
        'حدث خطأ غير متوقع أثناء تحميل التفاصيل.',
      );
    }
  }

  Future<AppointmentDetails> update({
    required int appointmentId,
    required DateTime requestedStartAt,
    required DateTime? confirmedStartAt,
    required String? adminNotes,
  }) {
    return _mutate(
      '/admin/appointments/$appointmentId',
      method: 'patch',
      data: {
        'requested_start_at': requestedStartAt.toUtc().toIso8601String(),
        'confirmed_start_at': confirmedStartAt?.toUtc().toIso8601String(),
        'admin_notes': _nullable(adminNotes),
      },
    );
  }

  Future<AppointmentDetails> confirm(
    int appointmentId, {
    DateTime? confirmedStartAt,
  }) {
    return _mutate(
      '/admin/appointments/$appointmentId/confirm',
      data: {
        if (confirmedStartAt != null)
          'confirmed_start_at': confirmedStartAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<AppointmentDetails> start(int appointmentId) {
    return _mutate('/admin/appointments/$appointmentId/start');
  }

  Future<AppointmentDetails> complete(int appointmentId) {
    return _mutate('/admin/appointments/$appointmentId/complete');
  }

  Future<AppointmentDetails> cancel(
    int appointmentId, {
    required String reason,
  }) {
    return _mutate(
      '/admin/appointments/$appointmentId/cancel',
      data: {'reason': reason.trim()},
    );
  }

  Future<AppointmentDetails> markNoShow(int appointmentId) {
    return _mutate('/admin/appointments/$appointmentId/no-show');
  }

  Future<AppointmentDetails> _mutate(
    String path, {
    String method = 'post',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = method == 'patch'
          ? await ApiClient.dio.patch(path, data: data)
          : await ApiClient.dio.post(path, data: data);
      final root = response.data;
      if (root is! Map || root['data'] is! Map) {
        throw const AppointmentException(
          'تم تنفيذ العملية لكن تعذر قراءة بيانات الموعد.',
        );
      }
      return AppointmentDetails.fromJson(
        Map<String, dynamic>.from(root['data'] as Map),
      );
    } on DioException catch (error) {
      throw AppointmentException(_message(error));
    }
  }

  static String? _nullable(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
    }
    return 'تعذر تنفيذ العملية على الموعد.';
  }
}
