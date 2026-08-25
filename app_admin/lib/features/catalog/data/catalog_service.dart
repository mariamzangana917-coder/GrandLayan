import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'catalog_models.dart';

class CatalogService {
  const CatalogService();

  Future<CatalogPage> fetchItems({
    required String department,
    String? type,
    String? search,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/admin/catalog-items',
        queryParameters: {
          'department': department,
          'type': ?type,
          'per_page': 100,
        },
      );

      if (response.data is! Map) {
        throw const CatalogException('استجابة غير صالحة من الخادم.');
      }

      final page = CatalogPage.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        apiBaseUrl: ApiClient.dio.options.baseUrl,
      );

      final query = search?.trim().toLowerCase() ?? '';

      final filtered = page.items.where((item) {
        if (item.departmentCode != department) {
          return false;
        }

        if (type != null && item.type != type) {
          return false;
        }

        if (query.isEmpty) return true;

        return item.name.toLowerCase().startsWith(query) ||
            item.name.toLowerCase().contains(query) ||
            item.categoryName.toLowerCase().contains(query) ||
            (item.description?.toLowerCase().contains(query) ?? false);
      }).toList();

      return CatalogPage(items: filtered, total: filtered.length);
    } on DioException catch (error) {
      throw CatalogException(_message(error, 'تعذر تحميل الخدمات والبكجات.'));
    }
  }

  Future<CatalogItem> fetchItem(int id) async {
    try {
      final response = await ApiClient.dio.get('/admin/catalog-items/$id');

      final root = response.data;

      if (root is! Map || root['data'] is! Map) {
        throw const CatalogException('تعذر قراءة تفاصيل العنصر.');
      }

      return CatalogItem.fromJson(
        Map<String, dynamic>.from(root['data'] as Map),
        apiBaseUrl: ApiClient.dio.options.baseUrl,
      );
    } on DioException catch (error) {
      throw CatalogException(_message(error, 'تعذر تحميل تفاصيل العنصر.'));
    }
  }

  Future<List<CatalogCategory>> fetchCategories(String department) async {
    try {
      final response = await ApiClient.dio.get(
        '/admin/categories',
        queryParameters: {'department': department, 'is_active': true},
      );

      final root = response.data;

      if (root is! Map || root['data'] is! List) {
        return const [];
      }

      return (root['data'] as List)
          .whereType<Map>()
          .map(
            (raw) => CatalogCategory.fromJson(Map<String, dynamic>.from(raw)),
          )
          .toList();
    } on DioException catch (error) {
      throw CatalogException(_message(error, 'تعذر تحميل التصنيفات.'));
    }
  }

  Future<void> updateItem({
    required int id,
    required int categoryId,
    required String name,
    required String type,
    required String priceType,
    required double? price,
    required int? durationMinutes,
    required String? description,
    required String? instructions,
    required bool isActive,
  }) async {
    try {
      await ApiClient.dio.patch(
        '/admin/catalog-items/$id',
        data: {
          'category_id': categoryId,
          'name': name.trim(),
          'type': type,
          'price_type': priceType,
          'price': priceType == 'fixed' ? price : null,
          'duration_minutes': durationMinutes,
          'description': _nullable(description),
          'instructions': _nullable(instructions),
          'is_active': isActive,
        },
      );
    } on DioException catch (error) {
      throw CatalogException(_message(error, 'تعذر حفظ التعديلات.'));
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await ApiClient.dio.delete('/admin/catalog-items/$id');
    } on DioException catch (error) {
      throw CatalogException(_message(error, 'تعذر حذف العنصر.'));
    }
  }

  Future<void> uploadImages(int itemId, List<String> paths) async {
    if (paths.isEmpty) return;

    final formData = FormData();

    for (final path in paths) {
      formData.files.add(
        MapEntry('images[]', await MultipartFile.fromFile(path)),
      );
    }

    try {
      await ApiClient.dio.post(
        '/admin/catalog-items/$itemId/images',
        data: formData,
      );
    } on DioException catch (error) {
      throw CatalogException(_message(error, 'تعذر رفع الصور.'));
    }
  }

  Future<void> deleteImage(int itemId, int imageId) async {
    try {
      await ApiClient.dio.delete(
        '/admin/catalog-items/$itemId/images/$imageId',
      );
    } on DioException catch (error) {
      throw CatalogException(_message(error, 'تعذر حذف الصورة.'));
    }
  }

  Future<void> setMainImage(int itemId, int imageId) async {
    try {
      await ApiClient.dio.patch(
        '/admin/catalog-items/$itemId/images/$imageId',
        data: {'is_primary': true},
      );
    } on DioException catch (error) {
      throw CatalogException(_message(error, 'تعذر تعيين الصورة الرئيسية.'));
    }
  }

  static String? _nullable(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _message(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message']?.toString();

      if (message != null && message.trim().isNotEmpty) {
        return message;
      }

      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }

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

class CatalogException implements Exception {
  const CatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}
