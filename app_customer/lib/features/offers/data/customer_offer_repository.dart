import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'customer_offer.dart';

abstract interface class CustomerOfferRepository {
  Future<List<CustomerOffer>> fetchOffers({String? department});
}

abstract interface class CustomerOfferDataSource {
  Future<Map<String, dynamic>> fetchOffers({String? department});
}

class CustomerOfferApiDataSource implements CustomerOfferDataSource {
  CustomerOfferApiDataSource({ApiClient? apiClient})
    : _apiClient =
          apiClient ?? ApiClient(storage: const SecureStorageService());

  final ApiClient _apiClient;

  @override
  Future<Map<String, dynamic>> fetchOffers({String? department}) {
    return _apiClient.get(
      '/customer/offers',
      queryParameters: <String, dynamic>{
        if (department != null && department.trim().isNotEmpty)
          'department': department.trim(),
      },
    );
  }
}

class CustomerOfferApiRepository implements CustomerOfferRepository {
  CustomerOfferApiRepository({CustomerOfferDataSource? dataSource})
    : _dataSource = dataSource ?? CustomerOfferApiDataSource();

  final CustomerOfferDataSource _dataSource;

  @override
  Future<List<CustomerOffer>> fetchOffers({String? department}) async {
    try {
      final Map<String, dynamic> response = await _dataSource.fetchOffers(
        department: department,
      );
      final List<dynamic> data = _extractList(response);

      return data
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) => CustomerOffer.fromJson(
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
      throw const ApiException(
        message: 'تعذر تحميل العروض حاليًا. حاولي مرة ثانية.',
      );
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final dynamic data = response['data'];
    if (data is List) {
      return data;
    }
    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    throw const FormatException('تنسيق بيانات العروض غير صالح.');
  }
}
