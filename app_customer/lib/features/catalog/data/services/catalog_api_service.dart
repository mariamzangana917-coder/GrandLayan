import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class CatalogApiService {
  CatalogApiService({ApiClient? apiClient})
    : _apiClient =
          apiClient ?? ApiClient(storage: const SecureStorageService());

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getCatalogItems({
    String? department,
    int? categoryId,
    String? type,
  }) {
    final Map<String, dynamic> queryParameters = <String, dynamic>{};

    if (department != null && department.isNotEmpty) {
      queryParameters['department'] = department;
    }

    if (categoryId != null) {
      queryParameters['category_id'] = categoryId;
    }

    if (type != null && type.isNotEmpty) {
      queryParameters['type'] = type;
    }

    return _apiClient.get(
      '/customer/catalog-items',
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> getCatalogItem(int catalogItemId) {
    return _apiClient.get('/customer/catalog-items/$catalogItemId');
  }
}
