import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'post_model.dart';

class PostService {
  PostService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<List<PostModel>> fetchPosts({required String department}) async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        '/posts',
        queryParameters: <String, dynamic>{'department': department},
      );

      final Map<String, dynamic> body = _asMap(response.data);

      final Object? rawData = body['data'];

      if (rawData is! List) {
        throw const ApiException(message: 'بيانات المنشورات غير صالحة.');
      }

      return rawData
          .whereType<Map>()
          .map((item) => PostModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'تعذر تحميل المنشورات.');
    }
  }

  Future<PostModel> createPost({
    required String department,
    required File image,
    String? description,
  }) async {
    if (!await image.exists()) {
      throw const ApiException(message: 'الصورة المختارة غير موجودة.');
    }

    try {
      final String fileName = _fileName(image);

      final FormData formData = FormData.fromMap(<String, dynamic>{
        'department': department,
        'description': description,
        'is_active': '1',
        'image': await MultipartFile.fromFile(image.path, filename: fileName),
      });

      final Response<dynamic> response = await _apiClient.post(
        '/admin/posts',
        data: formData,
      );

      final Map<String, dynamic> body = _asMap(response.data);

      final Object? rawData = body['data'];

      if (rawData is! Map) {
        throw const ApiException(message: 'بيانات المنشور المنشأ غير صالحة.');
      }

      return PostModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (error) {
      throw _handleDioError(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'تعذر إضافة المنشور.');
    }
  }

  Future<PostModel> updatePostDescription({
    required int postId,
    required String? description,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.patch(
        '/admin/posts/$postId',
        data: <String, dynamic>{'description': description},
      );

      final Map<String, dynamic> body = _asMap(response.data);

      final Object? rawData = body['data'];

      if (rawData is! Map) {
        throw const ApiException(
          message: 'بيانات المنشور بعد تعديل الوصف غير صالحة.',
        );
      }

      return PostModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (error) {
      throw _handleDioError(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'تعذر تعديل وصف المنشور.');
    }
  }

  Future<PostModel> updatePostStatus({
    required int postId,
    required bool isActive,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.patch(
        '/admin/posts/$postId',
        data: <String, dynamic>{'is_active': isActive},
      );

      final Map<String, dynamic> body = _asMap(response.data);

      final Object? rawData = body['data'];

      if (rawData is! Map) {
        throw const ApiException(
          message: 'بيانات المنشور بعد تحديث الحالة غير صالحة.',
        );
      }

      return PostModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (error) {
      throw _handleDioError(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'تعذر تحديث حالة المنشور.');
    }
  }

  Future<PostModel> replacePostImage({
    required int postId,
    required File image,
  }) async {
    if (!await image.exists()) {
      throw const ApiException(message: 'الصورة المختارة غير موجودة.');
    }

    try {
      final String fileName = _fileName(image);

      final FormData formData = FormData.fromMap(<String, dynamic>{
        'image': await MultipartFile.fromFile(image.path, filename: fileName),
      });

      final Response<dynamic> response = await _apiClient.post(
        '/admin/posts/$postId/image',
        data: formData,
      );

      final Map<String, dynamic> body = _asMap(response.data);
      final Object? rawData = body['data'];

      if (rawData is! Map) {
        throw const ApiException(
          message: 'بيانات المنشور بعد تغيير الصورة غير صالحة.',
        );
      }

      return PostModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (error) {
      throw _handleDioError(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'تعذر تغيير صورة المنشور.');
    }
  }

  Future<void> deletePost({required int postId}) async {
    try {
      await _apiClient.delete('/admin/posts/$postId');
    } on DioException catch (error) {
      throw _handleDioError(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'تعذر حذف المنشور.');
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw const ApiException(message: 'استجابة الخادم غير صالحة.');
  }

  ApiException _handleDioError(DioException error) {
    final int? statusCode = error.response?.statusCode;

    if (statusCode == 401) {
      return const ApiException(message: 'انتهت جلسة تسجيل الدخول.');
    }

    if (statusCode == 403) {
      return const ApiException(message: 'ليس لديك صلاحية لإدارة المنشورات.');
    }

    if (statusCode == 404) {
      return const ApiException(message: 'المنشور غير موجود.');
    }

    if (statusCode == 422) {
      final Object? data = error.response?.data;

      if (data is Map) {
        final Object? message = data['message'];

        if (message != null && message.toString().trim().isNotEmpty) {
          return ApiException(message: message.toString());
        }

        final Object? errors = data['errors'];

        if (errors is Map) {
          for (final Object? value in errors.values) {
            if (value is List && value.isNotEmpty) {
              return ApiException(message: value.first.toString());
            }

            if (value != null) {
              return ApiException(message: value.toString());
            }
          }
        }
      }

      return const ApiException(message: 'البيانات المرسلة غير صحيحة.');
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(message: 'تعذر الاتصال بالخادم.');
    }

    return const ApiException(message: 'حدث خطأ أثناء الاتصال بالخادم.');
  }

  String _fileName(File image) {
    final String path = image.path;

    final int separator = path.lastIndexOf(Platform.pathSeparator);

    if (separator == -1) {
      return path;
    }

    return path.substring(separator + 1);
  }
}
