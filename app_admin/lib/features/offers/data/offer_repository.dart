import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'admin_offer.dart';

abstract interface class OfferRepository {
  Future<AdminOfferPage> fetchOffers({
    String? search,
    String? department,
    String? availability,
    bool? isActive,
    int page = 1,
  });

  Future<List<OfferDepartment>> fetchDepartments();

  Future<List<OfferCatalogItem>> fetchCatalogItems({
    required String departmentCode,
  });

  Future<AdminOffer> createOffer({
    required Map<String, dynamic> fields,
    required String imagePath,
  });

  Future<AdminOffer> updateOffer({
    required int offerId,
    required Map<String, dynamic> fields,
  });

  Future<AdminOffer> replaceImage({
    required int offerId,
    required String imagePath,
  });

  Future<void> deleteOffer(int offerId);
}

class OfferApiRepository implements OfferRepository {
  const OfferApiRepository({Dio? dio}) : _dio = dio;

  final Dio? _dio;

  Dio get _client => _dio ?? ApiClient.dio;

  @override
  Future<AdminOfferPage> fetchOffers({
    String? search,
    String? department,
    String? availability,
    bool? isActive,
    int page = 1,
  }) async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        '/admin/offers',
        queryParameters: <String, dynamic>{
          'page': page < 1 ? 1 : page,
          'per_page': 20,
          if (_hasText(search)) 'search': search!.trim(),
          if (_hasText(department)) 'department': department!.trim(),
          if (_hasText(availability)) 'availability': availability!.trim(),
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      );

      return AdminOfferPage.fromJson(_responseMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<OfferDepartment>> fetchDepartments() async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        '/admin/departments',
        queryParameters: const <String, dynamic>{
          'is_active': 1,
          'per_page': 100,
        },
      );

      final Map<String, dynamic> root = _responseMap(response.data);
      final dynamic rawData = root['data'];
      final List<OfferDepartment> departments = <OfferDepartment>[];

      if (rawData is List) {
        for (final dynamic item in rawData) {
          if (item is Map) {
            departments.add(
              OfferDepartment.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      return departments;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<OfferCatalogItem>> fetchCatalogItems({
    required String departmentCode,
  }) async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        '/admin/catalog-items',
        queryParameters: <String, dynamic>{
          'department': departmentCode.trim(),
          'is_active': 1,
          'per_page': 100,
        },
      );

      final Map<String, dynamic> root = _responseMap(response.data);
      final dynamic rawData = root['data'];
      final List<OfferCatalogItem> items = <OfferCatalogItem>[];

      if (rawData is List) {
        for (final dynamic item in rawData) {
          if (item is Map) {
            items.add(
              OfferCatalogItem.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      return items;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AdminOffer> createOffer({
    required Map<String, dynamic> fields,
    required String imagePath,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        ..._multipartFields(fields),
        'image': await MultipartFile.fromFile(imagePath),
      });

      final Response<dynamic> response = await _client.post<dynamic>(
        '/admin/offers',
        data: formData,
      );

      return _singleOffer(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AdminOffer> updateOffer({
    required int offerId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final Response<dynamic> response = await _client.patch<dynamic>(
        '/admin/offers/$offerId',
        data: fields,
      );

      return _singleOffer(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AdminOffer> replaceImage({
    required int offerId,
    required String imagePath,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'image': await MultipartFile.fromFile(imagePath),
      });

      final Response<dynamic> response = await _client.post<dynamic>(
        '/admin/offers/$offerId/image',
        data: formData,
      );

      return _singleOffer(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> deleteOffer(int offerId) async {
    try {
      await _client.delete<dynamic>('/admin/offers/$offerId');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  AdminOffer _singleOffer(dynamic responseData) {
    final Map<String, dynamic> root = _responseMap(responseData);
    final dynamic rawData = root['data'];

    if (rawData is! Map) {
      throw const ApiException(message: 'استجابة العرض غير صالحة من الخادم.');
    }

    return AdminOffer.fromJson(Map<String, dynamic>.from(rawData));
  }

  Map<String, dynamic> _responseMap(dynamic responseData) {
    if (responseData is! Map) {
      throw const ApiException(message: 'استجابة غير صالحة من الخادم.');
    }

    return Map<String, dynamic>.from(responseData);
  }

  Map<String, dynamic> _multipartFields(Map<String, dynamic> fields) {
    final Map<String, dynamic> normalized = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in fields.entries) {
      final dynamic value = entry.value;

      if (value == null) {
        continue;
      }

      if (value is bool) {
        normalized[entry.key] = value ? '1' : '0';
      } else {
        normalized[entry.key] = value.toString();
      }
    }

    return normalized;
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
