import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'dashboard_model.dart';

class DashboardService {
  const DashboardService();

  Future<DashboardModel> fetchDashboard() async {
    try {
      final response = await ApiClient.dio.get('/admin/dashboard');

      final responseData = response.data;

      if (responseData is! Map) {
        throw const DashboardException('استجابة غير صالحة من الخادم.');
      }

      final root = Map<String, dynamic>.from(responseData);

      final data = root['data'];

      if (data is! Map) {
        throw const DashboardException('بيانات الصفحة الرئيسية غير موجودة.');
      }

      return DashboardModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        throw const DashboardException('انتهت جلسة تسجيل الدخول.');
      }

      if (statusCode == 403) {
        throw const DashboardException(
          'الحساب غير مخول للوصول إلى لوحة الإدارة.',
        );
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const DashboardException('تعذر الاتصال بالخادم.');
      }

      throw const DashboardException('تعذر تحميل بيانات الصفحة الرئيسية.');
    } on DashboardException {
      rethrow;
    } catch (_) {
      throw const DashboardException('حدث خطأ غير متوقع.');
    }
  }
}

class DashboardException implements Exception {
  const DashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
