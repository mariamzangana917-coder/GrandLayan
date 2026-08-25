import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'gift_card.dart';

class GiftCardService {
  const GiftCardService();

  static const String _path = '/admin/gift-card-designs';

  Future<List<GiftCard>> fetchGiftCards({bool? isActive}) async {
    try {
      final response = await ApiClient.dio.get(
        _path,
        queryParameters: {'is_active': ?isActive},
      );

      final root = response.data;

      if (root is! Map || root['data'] is! List) {
        throw const GiftCardException('استجابة بطاقات الهدايا غير صالحة.');
      }

      return (root['data'] as List)
          .whereType<Map>()
          .map((raw) => GiftCard.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw GiftCardException(_message(error, 'تعذر تحميل بطاقات الهدايا.'));
    }
  }

  Future<GiftCard> fetchGiftCard(int id) async {
    try {
      final response = await ApiClient.dio.get('$_path/$id');

      final root = response.data;

      /*
       * Laravel JsonResource يرجع العنصر داخل data:
       * {
       *   "data": {...}
       * }
       */
      if (root is! Map || root['data'] is! Map) {
        throw const GiftCardException('تعذر قراءة بيانات بطاقة الهدية.');
      }

      return GiftCard.fromJson(Map<String, dynamic>.from(root['data'] as Map));
    } on DioException catch (error) {
      throw GiftCardException(_message(error, 'تعذر تحميل بطاقة الهدية.'));
    }
  }

  Future<GiftCard> createGiftCard({
    required String name,
    required int amount,
    required int validityDays,
    required bool isActive,
    required int sortOrder,
    String? description,
    String? imageFilePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name.trim(),
        'description': _nullable(description),
        'amount': amount,
        'validity_days': validityDays,
        'is_active': isActive ? 1 : 0,
        'sort_order': sortOrder,
      });

      final imagePath = imageFilePath?.trim();

      if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(imagePath)),
        );
      }

      final response = await ApiClient.dio.post(_path, data: formData);

      return _readGiftCard(
        response.data,
        fallback: 'تعذر قراءة البطاقة بعد إضافتها.',
      );
    } on DioException catch (error) {
      throw GiftCardException(_message(error, 'تعذر إضافة بطاقة الهدية.'));
    }
  }

  Future<GiftCard> updateGiftCard({
    required int id,
    required String name,
    required int amount,
    required int validityDays,
    required bool isActive,
    required int sortOrder,
    String? description,
    String? imageFilePath,
  }) async {
    try {
      /*
       * نستخدم POST مع _method = PATCH لأن Laravel وPHP
       * يتعاملان مع multipart/form-data بهذه الطريقة بصورة أوثق.
       */
      final formData = FormData.fromMap({
        '_method': 'PATCH',
        'name': name.trim(),
        'description': _nullable(description),
        'amount': amount,
        'validity_days': validityDays,
        'is_active': isActive ? 1 : 0,
        'sort_order': sortOrder,
      });

      final imagePath = imageFilePath?.trim();

      if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(imagePath)),
        );
      }

      final response = await ApiClient.dio.post('$_path/$id', data: formData);

      return _readGiftCard(
        response.data,
        fallback: 'تعذر قراءة البطاقة بعد تعديلها.',
      );
    } on DioException catch (error) {
      throw GiftCardException(_message(error, 'تعذر تعديل بطاقة الهدية.'));
    }
  }

  Future<GiftCard> updateActiveStatus({
    required GiftCard giftCard,
    required bool isActive,
  }) async {
    try {
      final response = await ApiClient.dio.patch(
        '$_path/${giftCard.id}',
        data: {
          'name': giftCard.name,
          'description': _nullable(giftCard.description),
          'amount': giftCard.amount,
          'validity_days': giftCard.validityDays,
          'is_active': isActive,
          'sort_order': giftCard.sortOrder,
        },
      );

      return _readGiftCard(
        response.data,
        fallback: 'تعذر قراءة البطاقة بعد تغيير حالتها.',
      );
    } on DioException catch (error) {
      throw GiftCardException(
        _message(
          error,
          isActive ? 'تعذر تفعيل بطاقة الهدية.' : 'تعذر إيقاف بطاقة الهدية.',
        ),
      );
    }
  }

  Future<GiftCard> deleteImage(int id) async {
    try {
      final response = await ApiClient.dio.delete('$_path/$id/image');

      return _readGiftCard(
        response.data,
        fallback: 'تعذر قراءة البطاقة بعد حذف الصورة.',
      );
    } on DioException catch (error) {
      throw GiftCardException(_message(error, 'تعذر حذف صورة بطاقة الهدية.'));
    }
  }

  Future<void> deleteGiftCard(int id) async {
    try {
      await ApiClient.dio.delete('$_path/$id');
    } on DioException catch (error) {
      throw GiftCardException(_message(error, 'تعذر حذف بطاقة الهدية.'));
    }
  }

  String? buildImageUrl(String? imagePath) {
    final path = imagePath?.trim();

    if (path == null || path.isEmpty) {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    var baseUrl = ApiClient.dio.options.baseUrl.trim();

    while (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }

    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    if (normalizedPath.startsWith('storage/')) {
      return '$baseUrl/$normalizedPath';
    }

    return '$baseUrl/storage/$normalizedPath';
  }

  static GiftCard _readGiftCard(
    dynamic responseData, {
    required String fallback,
  }) {
    if (responseData is! Map || responseData['data'] is! Map) {
      throw GiftCardException(fallback);
    }

    return GiftCard.fromJson(
      Map<String, dynamic>.from(responseData['data'] as Map),
    );
  }

  static String? _nullable(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static String _message(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message']?.toString();

      if (message != null && message.trim().isNotEmpty) {
        return message;
      }

      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }

        return first.toString();
      }
    }

    if (error.response?.statusCode == 401) {
      return 'انتهت جلسة تسجيل الدخول.';
    }

    if (error.response?.statusCode == 403) {
      return 'ليس لديك صلاحية لتنفيذ هذه العملية.';
    }

    if (error.response?.statusCode == 404) {
      return 'بطاقة الهدية غير موجودة.';
    }

    if (error.response?.statusCode == 422) {
      return fallback;
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'تعذر الاتصال بالخادم.';
    }

    return fallback;
  }
}

class GiftCardException implements Exception {
  const GiftCardException(this.message);

  final String message;

  @override
  String toString() => message;
}
