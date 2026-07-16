import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import 'admin_category_model.dart';

class AdminCategoryService {
  const AdminCategoryService();

  Future<List<AdminCategory>> fetchCategories(String departmentCode) async {
    try {
      final response = await ApiClient.dio.get(
        '/admin/categories',
        queryParameters: {'department': departmentCode},
      );

      final root = response.data;
      if (root is! Map || root['data'] is! List) {
        throw const AdminCategoryException('تعذر قراءة التصنيفات.');
      }

      return (root['data'] as List)
          .whereType<Map>()
          .map(
            (item) => AdminCategory.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (error) {
      throw AdminCategoryException(_message(error, 'تعذر تحميل التصنيفات.'));
    }
  }

  Future<AdminCategory> createCategory({
    required int departmentId,
    required String name,
    required String? description,
    required bool isActive,
    String? imagePath,
  }) async {
    try {
      final data = FormData.fromMap({
        'department_id': departmentId,
        'name': name.trim(),
        'description': _nullable(description),
        'is_active': isActive ? 1 : 0,
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await ApiClient.dio.post(
        '/admin/categories',
        data: data,
      );

      return _fromResponse(response.data);
    } on DioException catch (error) {
      throw AdminCategoryException(_message(error, 'تعذر إنشاء التصنيف.'));
    }
  }

  Future<AdminCategory> updateCategory({
    required int categoryId,
    required int departmentId,
    required String name,
    required String? description,
    required bool isActive,
    String? imagePath,
  }) async {
    try {
      final data = FormData.fromMap({
        '_method': 'PATCH',
        'department_id': departmentId,
        'name': name.trim(),
        'description': _nullable(description),
        'is_active': isActive ? 1 : 0,
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await ApiClient.dio.post(
        '/admin/categories/$categoryId',
        data: data,
      );

      return _fromResponse(response.data);
    } on DioException catch (error) {
      throw AdminCategoryException(_message(error, 'تعذر تحديث التصنيف.'));
    }
  }

  Future<void> deleteImage(int categoryId) async {
    try {
      await ApiClient.dio.delete('/admin/categories/$categoryId/image');
    } on DioException catch (error) {
      throw AdminCategoryException(_message(error, 'تعذر حذف الصورة.'));
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await ApiClient.dio.delete('/admin/categories/$categoryId');
    } on DioException catch (error) {
      throw AdminCategoryException(_message(error, 'تعذر حذف التصنيف.'));
    }
  }

  AdminCategory _fromResponse(dynamic responseData) {
    if (responseData is! Map || responseData['data'] is! Map) {
      throw const AdminCategoryException(
        'تم الحفظ لكن تعذر قراءة بيانات التصنيف.',
      );
    }

    return AdminCategory.fromJson(
      Map<String, dynamic>.from(responseData['data'] as Map),
    );
  }

  static String? _nullable(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _message(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message;

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'تعذر الاتصال بالخادم.';
    }

    return fallback;
  }
}

class AdminCategoryException implements Exception {
  const AdminCategoryException(this.message);
  final String message;
}
