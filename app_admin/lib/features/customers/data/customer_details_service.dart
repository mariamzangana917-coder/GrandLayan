import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'customer_details_model.dart';
import 'customer_service.dart';

class CustomerDetailsService {
  const CustomerDetailsService();

  Future<CustomerDetails> fetchDetails(int customerId) async {
    try {
      final response = await ApiClient.dio.get('/admin/customers/$customerId');

      final root = response.data;
      if (root is! Map || root['data'] is! Map) {
        throw const CustomerException('تفاصيل العميلة غير موجودة.');
      }

      return CustomerDetails.fromJson(
        Map<String, dynamic>.from(root['data'] as Map),
      );
    } on DioException catch (error) {
      final code = error.response?.statusCode;

      if (code == 401) {
        throw const CustomerException('انتهت جلسة تسجيل الدخول.');
      }
      if (code == 403) {
        throw const CustomerException('الحساب غير مخول لعرض التفاصيل.');
      }
      if (code == 404) {
        throw const CustomerException('العميلة غير موجودة.');
      }

      throw const CustomerException('تعذر تحميل تفاصيل العميلة.');
    }
  }
}
