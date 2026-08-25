import '../../../../core/network/api_exception.dart';
import '../models/post_model.dart';
import '../services/post_api_service.dart';

class PostRepository {
  PostRepository({PostApiService? apiService})
    : _apiService = apiService ?? PostApiService();

  final PostApiService _apiService;

  Future<List<PostModel>> getPosts({
    required String department,
  }) async {
    try {
      final Map<String, dynamic> response = await _apiService.getPosts(
        department: department,
      );

      final List<dynamic> items = _extractList(response);

      return items
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) => PostModel.fromJson(
              item.map(
                (dynamic key, dynamic value) =>
                    MapEntry(key.toString(), value),
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
        message: 'تعذر تحميل المنشورات حالياً.',
      );
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

    throw const FormatException(
      'تنسيق بيانات المنشورات غير صحيح.',
    );
  }
}
