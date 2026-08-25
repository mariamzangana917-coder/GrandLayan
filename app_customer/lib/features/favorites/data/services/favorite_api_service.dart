import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class FavoriteApiService {
  FavoriteApiService({ApiClient? apiClient})
    : _apiClient =
          apiClient ?? ApiClient(storage: const SecureStorageService());

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getFavorites() {
    return _apiClient.get('/customer/favorites');
  }

  Future<Map<String, dynamic>> addFavorite(int catalogItemId) {
    return _apiClient.post('/customer/favorites/$catalogItemId');
  }

  Future<Map<String, dynamic>> removeFavorite(int catalogItemId) {
    return _apiClient.delete('/customer/favorites/$catalogItemId');
  }
}
