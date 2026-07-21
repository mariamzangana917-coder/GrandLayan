import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class CatalogApiService {
  const CatalogApiService({
    this.apiClient = const ApiClient(),
  });

  final ApiClient apiClient;

  Future<Response<dynamic>> getCatalogItems({
    String? department,
    int? categoryId,
    String? type,
  }) {
    final queryParameters = <String, dynamic>{};

    if (department != null && department.trim().isNotEmpty) {
      queryParameters['department'] = department.trim();
    }

    if (categoryId != null) {
      queryParameters['category_id'] = categoryId;
    }

    if (type != null && type.trim().isNotEmpty) {
      queryParameters['type'] = type.trim();
    }

    return apiClient.get(
      '/admin/catalog-items',
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> getCatalogItem(int catalogItemId) {
    return apiClient.get(
      '/admin/catalog-items/$catalogItemId',
    );
  }
}