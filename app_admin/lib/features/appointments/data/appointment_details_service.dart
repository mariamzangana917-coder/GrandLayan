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
}
