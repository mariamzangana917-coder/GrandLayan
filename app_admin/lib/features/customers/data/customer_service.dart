import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'customer_model.dart';

class CustomerService {
  const CustomerService();

  Future<CustomerListResponse> fetchCustomers({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
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

      if (isActive != null) {
        queryParameters['is_active'] = isActive ? 1 : 0;
      }

      final response = await ApiClient.dio.get(
        '/admin/customers',
        queryParameters: queryParameters,
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw const CustomerException('استجابة غير صالحة من الخادم.');
      }

      return CustomerListResponse.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        throw const CustomerException('انتهت جلسة تسجيل الدخول.');
      }

      if (statusCode == 403) {
        throw const CustomerException('الحساب غير مخول لعرض العملاء.');
      }

      if (statusCode == 422) {
        throw const CustomerException('بيانات البحث أو الفلترة غير صحيحة.');
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const CustomerException('تعذر الاتصال بالخادم.');
      }

      throw const CustomerException('تعذر تحميل العملاء حاليًا.');
    } on CustomerException {
      rethrow;
    } catch (_) {
      throw const CustomerException('حدث خطأ غير متوقع أثناء تحميل العملاء.');
    }
  }
}

class CustomerException implements Exception {
  const CustomerException(this.message);

  final String message;

  @override
  String toString() => message;
}
