import '../../../../core/network/api_exception.dart';
import '../models/favorite_item.dart';
import '../services/favorite_api_service.dart';

class FavoriteRepository {
  FavoriteRepository({FavoriteApiService? apiService})
    : _apiService = apiService ?? FavoriteApiService();

  final FavoriteApiService _apiService;

  Future<List<FavoriteItem>> getFavorites() async {
    try {
      final Map<String, dynamic> response = await _apiService.getFavorites();

      final List<dynamic> items = _extractList(response);

      return items
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) => FavoriteItem.fromJson(
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
      throw const ApiException(message: 'تعذر تحميل المفضلة حالياً.');
    }
  }

  Future<void> addFavorite(int catalogItemId) async {
    await _apiService.addFavorite(catalogItemId);
  }

  Future<void> removeFavorite(int catalogItemId) async {
    await _apiService.removeFavorite(catalogItemId);
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

    throw const FormatException('تنسيق بيانات المفضلة غير صحيح.');
  }
}
