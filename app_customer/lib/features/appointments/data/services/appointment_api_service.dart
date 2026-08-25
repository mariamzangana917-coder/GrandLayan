import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AppointmentApiService {
  AppointmentApiService({ApiClient? apiClient})
    : _apiClient =
          apiClient ?? ApiClient(storage: const SecureStorageService());

  final ApiClient _apiClient;

Future<Map<String, dynamic>> createAppointment({
  required int departmentId,
  required DateTime requestedStartAt,
  required List<Map<String, dynamic>> items,
  String? customerNotes,
  String? couponCode,
}) {
  final String? normalizedNotes = customerNotes?.trim();
  final String? normalizedCouponCode = couponCode?.trim();

  return _apiClient.post(
    '/appointments',
    data: <String, dynamic>{
      'department_id': departmentId,

      // نحول الوقت المحلي إلى UTC قبل الإرسال.
      'requested_start_at': requestedStartAt.toUtc().toIso8601String(),

      'customer_notes':
          normalizedNotes == null || normalizedNotes.isEmpty
              ? null
              : normalizedNotes,

      'coupon_code':
          normalizedCouponCode == null || normalizedCouponCode.isEmpty
              ? null
              : normalizedCouponCode,

      'items': items,
    },
  );
}

  Future<Map<String, dynamic>> getAppointments({int page = 1}) {
    return _apiClient.get(
      '/appointments',
      queryParameters: <String, dynamic>{'page': page},
    );
  }

  Future<Map<String, dynamic>> getAppointment(int appointmentId) {
    return _apiClient.get('/appointments/$appointmentId');
  }

  Future<Map<String, dynamic>> cancelAppointment({
    required int appointmentId,
    required String reason,
  }) {
    return _apiClient.post(
      '/appointments/$appointmentId/cancel',
      data: <String, dynamic>{'reason': reason.trim()},
    );
  }
}
