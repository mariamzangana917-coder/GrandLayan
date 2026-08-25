import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'admin_coupon.dart';

abstract interface class CouponRepository {
  Future<AdminCouponPage> fetchCoupons({
    String? search,
    int? departmentId,
    String? discountType,
    String? availability,
    bool? isActive,
    int page = 1,
  });

  Future<AdminCoupon> fetchCoupon(int couponId);

  Future<List<CouponDepartment>> fetchDepartments();

  Future<List<CouponCatalogItem>> fetchCatalogItems({String? departmentCode});

  Future<AdminCoupon> createCoupon(Map<String, dynamic> fields);

  Future<AdminCoupon> updateCoupon({
    required int couponId,
    required Map<String, dynamic> fields,
  });

  Future<CouponDeleteResult> deleteCoupon(int couponId);
}

class CouponApiRepository implements CouponRepository {
  const CouponApiRepository({Dio? dio}) : _dio = dio;

  final Dio? _dio;

  Dio get _client => _dio ?? ApiClient.dio;

  @override
  Future<AdminCouponPage> fetchCoupons({
    String? search,
    int? departmentId,
    String? discountType,
    String? availability,
    bool? isActive,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = <String, dynamic>{
        'page': page < 1 ? 1 : page,
        'per_page': 20,
      };

      final String? normalizedSearch = _trimOrNull(search);
      final String? normalizedDiscountType = _trimOrNull(discountType);
      final String? normalizedAvailability = _trimOrNull(availability);

      if (normalizedSearch != null) {
        queryParameters['search'] = normalizedSearch;
      }

      if (departmentId != null) {
        queryParameters['department_id'] = departmentId;
      }

      if (normalizedDiscountType != null) {
        queryParameters['discount_type'] = normalizedDiscountType;
      }

      if (normalizedAvailability != null) {
        queryParameters['availability'] = normalizedAvailability;
      }

      if (isActive != null) {
        queryParameters['is_active'] = isActive ? 1 : 0;
      }

      final Response<dynamic> response = await _client.get<dynamic>(
        '/admin/coupons',
        queryParameters: queryParameters,
      );

      return AdminCouponPage.fromJson(_responseMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AdminCoupon> fetchCoupon(int couponId) async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        '/admin/coupons/$couponId',
      );

      return _singleCoupon(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<CouponDepartment>> fetchDepartments() async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        '/admin/departments',
        queryParameters: const <String, dynamic>{
          'is_active': 1,
          'per_page': 100,
        },
      );

      return _departmentsFromList(_responseMap(response.data)['data']);
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        throw ApiException.fromDio(error);
      }

      return _fetchDepartmentsFromAppointmentFilters();
    }
  }

  Future<List<CouponDepartment>>
  _fetchDepartmentsFromAppointmentFilters() async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        '/admin/appointments',
        queryParameters: const <String, dynamic>{'per_page': 1},
      );

      final Map<String, dynamic> root = _responseMap(response.data);
      final dynamic rawFilters = root['filters'];

      if (rawFilters is! Map) {
        return const <CouponDepartment>[];
      }

      final Map<String, dynamic> filters = Map<String, dynamic>.from(
        rawFilters,
      );

      return _departmentsFromList(filters['departments']);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<CouponDepartment> _departmentsFromList(dynamic rawData) {
    final List<CouponDepartment> departments = <CouponDepartment>[];

    if (rawData is List) {
      for (final dynamic item in rawData) {
        if (item is Map) {
          departments.add(
            CouponDepartment.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return List<CouponDepartment>.unmodifiable(departments);
  }

  @override
  Future<List<CouponCatalogItem>> fetchCatalogItems({
    String? departmentCode,
  }) async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        '/admin/catalog-items',
        queryParameters: <String, dynamic>{
          if (_hasText(departmentCode)) 'department': departmentCode!.trim(),
          'is_active': 1,
          'per_page': 100,
        },
      );

      final Map<String, dynamic> root = _responseMap(response.data);
      final dynamic rawData = root['data'];
      final List<CouponCatalogItem> items = <CouponCatalogItem>[];

      if (rawData is List) {
        for (final dynamic item in rawData) {
          if (item is Map) {
            items.add(
              CouponCatalogItem.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      return List<CouponCatalogItem>.unmodifiable(items);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AdminCoupon> createCoupon(Map<String, dynamic> fields) async {
    try {
      final Response<dynamic> response = await _client.post<dynamic>(
        '/admin/coupons',
        data: fields,
      );

      return _singleCoupon(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AdminCoupon> updateCoupon({
    required int couponId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final Response<dynamic> response = await _client.patch<dynamic>(
        '/admin/coupons/$couponId',
        data: fields,
      );

      return _singleCoupon(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<CouponDeleteResult> deleteCoupon(int couponId) async {
    try {
      final Response<dynamic> response = await _client.delete<dynamic>(
        '/admin/coupons/$couponId',
      );

      return CouponDeleteResult.fromJson(_responseMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  AdminCoupon _singleCoupon(dynamic responseData) {
    final Map<String, dynamic> root = _responseMap(responseData);
    final dynamic rawData = root['data'];

    if (rawData is! Map) {
      throw const ApiException(message: 'استجابة الكوبون غير صالحة من الخادم.');
    }

    return AdminCoupon.fromJson(Map<String, dynamic>.from(rawData));
  }

  Map<String, dynamic> _responseMap(dynamic responseData) {
    if (responseData is! Map) {
      throw const ApiException(message: 'استجابة غير صالحة من الخادم.');
    }

    return Map<String, dynamic>.from(responseData);
  }

  String? _trimOrNull(String? value) {
    final String? trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
