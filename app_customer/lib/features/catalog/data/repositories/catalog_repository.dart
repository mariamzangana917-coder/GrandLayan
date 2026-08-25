import '../../../../core/network/api_exception.dart';
import '../models/catalog_item.dart';
import '../services/catalog_api_service.dart';

class CatalogRepository {
  CatalogRepository({CatalogApiService? apiService})
    : _apiService = apiService ?? CatalogApiService();

  final CatalogApiService _apiService;

  Future<List<CatalogItem>> getCatalogItems({
    String? department,
    int? categoryId,
    String? type,
  }) async {
    try {
      final Map<String, dynamic> response = await _apiService.getCatalogItems(
        department: department,
        categoryId: categoryId,
        type: type,
      );

      final List<dynamic> items = _extractList(response);

      return items
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) => CatalogItem.fromJson(
              item.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    } catch (_) {
      throw const ApiException(message: 'تعذر تحميل الخدمات حاليًا.');
    }
  }

  Future<CatalogItem> getCatalogItem(int catalogItemId) async {
    try {
      final Map<String, dynamic> response = await _apiService.getCatalogItem(
        catalogItemId,
      );

      final Map<String, dynamic> item = _extractObject(response);

      return CatalogItem.fromJson(item);
    } on ApiException {
      rethrow;
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    } catch (_) {
      throw const ApiException(message: 'تعذر تحميل تفاصيل الخدمة حاليًا.');
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> responseData) {
    final dynamic data = responseData['data'];

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final dynamic nestedData = data['data'];

      if (nestedData is List) {
        return nestedData;
      }
    }

    throw const FormatException('تنسيق بيانات الكتالوج غير صحيح.');
  }

  Map<String, dynamic> _extractObject(Map<String, dynamic> responseData) {
    dynamic value = responseData['data'] ?? responseData;

    if (value is Map && value.containsKey('data') && value['data'] is Map) {
      value = value['data'];
    }

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (dynamic key, dynamic itemValue) => MapEntry(key.toString(), itemValue),
      );
    }

    throw const FormatException('تنسيق بيانات تفاصيل الخدمة غير صحيح.');
  }
}
