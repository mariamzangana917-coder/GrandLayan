import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class PostApiService {
  PostApiService({ApiClient? apiClient})
    : _apiClient =
          apiClient ?? ApiClient(storage: const SecureStorageService());

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getPosts({
    required String department,
  }) {
    return _apiClient.get(
      '/posts',
      queryParameters: <String, dynamic>{
        'department': department,
      },
    );
  }
}
