import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/gift_card_design.dart';

class CustomerGiftCardsApi {
  CustomerGiftCardsApi({Dio? dio, FlutterSecureStorage? secureStorage})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://64.227.16.105/api',
              ),
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              responseType: ResponseType.json,
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ),
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  Future<List<GiftCardDesign>> getActiveDesigns() async {
    try {
      final token = await _readCustomerToken();

      final response = await _dio.get<dynamic>(
        '/customer/gift-card-designs',
        options: Options(headers: _authorizationHeaders(token)),
      );

      final rawData = response.data;
      final List<dynamic> items;

      if (rawData is List<dynamic>) {
        items = rawData;
      } else if (rawData is Map<String, dynamic>) {
        final data = rawData['data'];

        if (data is List<dynamic>) {
          items = data;
        } else {
          throw const CustomerGiftCardsException(
            'صيغة بيانات تصاميم بطاقات الهدايا غير صحيحة.',
          );
        }
      } else {
        throw const CustomerGiftCardsException('لم يستجب الخادم بصيغة صحيحة.');
      }

      final designs = items
          .whereType<Map<String, dynamic>>()
          .map(GiftCardDesign.fromJson)
          .where((design) => design.isActive)
          .toList();

      designs.sort((first, second) {
        final sortResult = first.sortOrder.compareTo(second.sortOrder);

        if (sortResult != 0) {
          return sortResult;
        }

        return first.id.compareTo(second.id);
      });

      return designs;
    } on DioException catch (error) {
      throw CustomerGiftCardsException(_messageFromDioException(error));
    } on CustomerGiftCardsException {
      rethrow;
    } catch (_) {
      throw const CustomerGiftCardsException(
        'حدث خطأ غير متوقع أثناء تحميل التصاميم.',
      );
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required int giftCardDesignId,
    required String recipientName,
    required String paymentMethod,
    String? recipientPhone,
    String? giftMessage,
  }) async {
    try {
      final token = await _readCustomerToken();

      if (token == null) {
        throw const CustomerGiftCardsException(
          'يجب تسجيل الدخول قبل شراء بطاقة هدية.',
        );
      }

      final response = await _dio.post<dynamic>(
        '/customer/gift-card-orders',
        data: {
          'gift_card_design_id': giftCardDesignId,
          'recipient_name': recipientName.trim(),
          'recipient_phone': _nullableText(recipientPhone),
          'gift_message': _nullableText(giftMessage),
          'payment_method': paymentMethod,
        },
        options: Options(headers: _authorizationHeaders(token)),
      );

      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];

        if (data is Map<String, dynamic>) {
          return data;
        }

        return responseData;
      }

      throw const CustomerGiftCardsException(
        'تم إرسال الطلب لكن استجابة الخادم غير صحيحة.',
      );
    } on DioException catch (error) {
      throw CustomerGiftCardsException(_messageFromDioException(error));
    } on CustomerGiftCardsException {
      rethrow;
    } catch (_) {
      throw const CustomerGiftCardsException(
        'حدث خطأ غير متوقع أثناء إنشاء الطلب.',
      );
    }
  }

  Map<String, String>? _authorizationHeaders(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    return {'Authorization': 'Bearer $token'};
  }

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  Future<String?> _readCustomerToken() async {
    const possibleKeys = <String>[
      'customer_access_token',
      'customer_token',
      'access_token',
      'auth_token',
      'token',
    ];

    for (final key in possibleKeys) {
      final value = await _secureStorage.read(key: key);

      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  String _messageFromDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    if (statusCode == 401) {
      return 'انتهت جلسة تسجيل الدخول. سجلي الدخول من جديد.';
    }

    if (statusCode == 403) {
      return 'ليس لديك صلاحية لتنفيذ هذا الطلب.';
    }

    if (statusCode == 404) {
      return 'المسار المطلوب غير موجود على الخادم.';
    }

    if (statusCode == 422) {
      return _validationMessage(responseData);
    }

    if (statusCode != null && statusCode >= 500) {
      return 'حدث خطأ داخل الخادم. حاولي مرة ثانية.';
    }

    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString().trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال بالخادم. تأكدي من الإنترنت.';

      case DioExceptionType.transformTimeout:
        return 'استغرق الخادم وقتًا طويلًا في معالجة البيانات.';

      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالخادم. تأكدي من الإنترنت وعنوان السيرفر.';

      case DioExceptionType.badCertificate:
        return 'تعذر التحقق من شهادة اتصال الخادم.';

      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب.';

      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return 'تعذر تنفيذ الطلب حاليًا.';
    }
  }

  String _validationMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final errors = responseData['errors'];

      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }

          if (value != null) {
            return value.toString();
          }
        }
      }

      final message = responseData['message']?.toString().trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return 'تأكدي من صحة البيانات المدخلة.';
  }
}

class CustomerGiftCardsException implements Exception {
  const CustomerGiftCardsException(this.message);

  final String message;

  @override
  String toString() => message;
}
