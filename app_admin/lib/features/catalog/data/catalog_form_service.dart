import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'catalog_form_models.dart';

class CatalogFormService {
  const CatalogFormService();

  Future<List<CatalogCategoryOption>> fetchCategories(
    String departmentCode,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        '/admin/categories',
        queryParameters: {'department': departmentCode, 'is_active': 1},
      );

      final root = response.data;

      if (root is! Map || root['data'] is! List) {
        throw const CatalogFormException('تعذر قراءة التصنيفات.');
      }

      return (root['data'] as List)
          .whereType<Map>()
          .map(
            (item) =>
                CatalogCategoryOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .where(
            (item) =>
                item.departmentCode.isEmpty ||
                item.departmentCode == departmentCode,
          )
          .toList();
    } on DioException catch (error) {
      throw CatalogFormException(
        _messageFromDio(error, fallback: 'تعذر تحميل التصنيفات.'),
      );
    }
  }

  Future<List<CatalogServiceOption>> fetchServices(
    String departmentCode,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        '/admin/catalog-items',
        queryParameters: {
          'department': departmentCode,
          'type': 'service',
          'is_active': 1,
          'per_page': 100,
        },
      );

      final root = response.data;

      if (root is! Map || root['data'] is! List) {
        throw const CatalogFormException('تعذر قراءة الخدمات.');
      }

      return (root['data'] as List)
          .whereType<Map>()
          .map(
            (item) =>
                CatalogServiceOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (error) {
      throw CatalogFormException(
        _messageFromDio(error, fallback: 'تعذر تحميل الخدمات.'),
      );
    }
  }

  Future<int> createCatalogItem({
    required int categoryId,
    required String type,
    required String name,
    required String? description,
    required String? instructions,
    required String priceType,
    required double? price,
    required int? durationMinutes,
    required bool isActive,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/admin/catalog-items',
        data: {
          'category_id': categoryId,
          'type': type,
          'name': name.trim(),
          'description': _nullable(description),
          'instructions': _nullable(instructions),
          'price_type': priceType,
          'price': priceType == 'fixed' ? price : null,
          'duration_minutes': durationMinutes,
          'is_active': isActive,
        },
      );

      final root = response.data;

      if (root is! Map || root['data'] is! Map) {
        throw const CatalogFormException('تم الحفظ لكن تعذر قراءة رقم العنصر.');
      }

      final data = Map<String, dynamic>.from(root['data'] as Map);

      final id = int.tryParse(data['id']?.toString() ?? '') ?? 0;

      if (id <= 0) {
        throw const CatalogFormException('الخادم لم يرجع رقم العنصر.');
      }

      return id;
    } on DioException catch (error) {
      throw CatalogFormException(
        _messageFromDio(error, fallback: 'تعذر إنشاء العنصر.'),
      );
    }
  }

  Future<void> uploadImages({
    required int catalogItemId,
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) return;

    try {
      final files = <MultipartFile>[];

      for (final path in imagePaths) {
        files.add(await MultipartFile.fromFile(path));
      }

      final formData = FormData();

      for (final file in files) {
        formData.files.add(MapEntry('images[]', file));
      }

      await ApiClient.dio.post(
        '/admin/catalog-items/$catalogItemId/images',
        data: formData,
      );
    } on DioException catch (error) {
      throw CatalogFormException(
        _messageFromDio(error, fallback: 'تم إنشاء العنصر لكن تعذر رفع الصور.'),
      );
    }
  }

  Future<void> addPackageServices({
    required int packageId,
    required List<PackageServiceDraft> services,
  }) async {
    for (final item in services) {
      try {
        await ApiClient.dio.post(
          '/admin/packages/$packageId/items',
          data: {
            'service_id': item.service.id,
            'quantity': item.quantity,
            'notes': _nullable(item.notes),
          },
        );
      } on DioException catch (error) {
        throw CatalogFormException(
          _messageFromDio(
            error,
            fallback: 'تم إنشاء البكج لكن تعذر إضافة بعض خدماته.',
          ),
        );
      }
    }
  }

  static String? _nullable(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _messageFromDio(
    DioException error, {
    required String fallback,
  }) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message']?.toString();

      if (message != null && message.trim().isNotEmpty) {
        return message;
      }

      final errors = responseData['errors'];

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

class CatalogFormException implements Exception {
  const CatalogFormException(this.message);

  final String message;

  @override
  String toString() => message;
}
