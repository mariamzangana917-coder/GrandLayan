import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'customer_banner.dart';

class BannerRepository {
  BannerRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient(storage: const SecureStorageService());
  final ApiClient _apiClient;
  Future<List<CustomerBanner>> fetch(String placement) async {
    final root = await _apiClient.get('/customer/banners', queryParameters: {'placement': placement});
    final data = root['data'];
    if (data is! List) throw const FormatException('Invalid banners response.');
    return data.whereType<Map>().map((value) => CustomerBanner.fromJson(Map<String, dynamic>.from(value))).toList(growable: false);
  }
}
