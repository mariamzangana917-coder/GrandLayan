import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../catalog_item.dart';
import '../services/catalog_api_service.dart';

class CatalogRepository {
  const CatalogRepository({this.apiService = const CatalogApiService()});

  final CatalogApiService apiService;

  Future<List<CatalogItem>> getCatalogItems({
    String? department,
    int? categoryId,
    String? type,
  }) async {
    try {
      final Response<dynamic> response = await apiService.getCatalogItems(
        department: department,
        categoryId: categoryId,
        type: type,
      );

      final List<dynamic> items = _extractList(response.data);

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
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CatalogItem> getCatalogItem(int catalogItemId) async {
    try {
      final Response<dynamic> response = await apiService.getCatalogItem(
        catalogItemId,
      );

      final Map<String, dynamic> item = _extractObject(response.data);

      return CatalogItem.fromJson(item);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }

    if (responseData is Map) {
      final dynamic data = responseData['data'];

      if (data is List) {
        return data;
      }
    }

    throw const FormatException('تنسيق بيانات الكتالوج غير صحيح.');
  }

  Map<String, dynamic> _extractObject(dynamic responseData) {
    dynamic value = responseData;

    if (responseData is Map && responseData.containsKey('data')) {
      value = responseData['data'];
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
