import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_admin/features/coupons/data/coupon_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late _QueueAdapter adapter;
  late CouponApiRepository repository;

  setUp(() {
    adapter = _QueueAdapter();
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://example.test/api',
        headers: const <String, dynamic>{'Accept': 'application/json'},
      ),
    )..httpClientAdapter = adapter;

    repository = CouponApiRepository(dio: dio);
  });

  tearDown(() {
    dio.close(force: true);
  });

  test('fetchCoupons sends supported filters and parses pagination', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': <Map<String, dynamic>>[_couponJson(id: 11)],
        'meta': const <String, dynamic>{
          'current_page': 2,
          'last_page': 4,
          'total': 61,
        },
      },
    );

    final page = await repository.fetchCoupons(
      search: 'WELCOME',
      departmentId: 1,
      discountType: 'percentage',
      availability: 'available',
      isActive: true,
      page: 2,
    );

    final RequestOptions request = adapter.requests.single;

    expect(request.method, 'GET');
    expect(request.uri.path, '/api/admin/coupons');
    expect(request.queryParameters['search'], 'WELCOME');
    expect(request.queryParameters['department_id'], 1);
    expect(request.queryParameters['discount_type'], 'percentage');
    expect(request.queryParameters['availability'], 'available');
    expect(request.queryParameters['is_active'], 1);
    expect(request.queryParameters['page'], 2);
    expect(page.items.single.id, 11);
    expect(page.hasMore, isTrue);
  });

  test('fetchDepartments requests active lookup', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': const <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'code': 'salon', 'name': 'الصالون'},
          <String, dynamic>{'id': 2, 'code': 'clinic', 'name': 'العيادة'},
        ],
      },
    );

    final departments = await repository.fetchDepartments();
    final RequestOptions request = adapter.requests.single;

    expect(request.uri.path, '/api/admin/departments');
    expect(request.queryParameters['is_active'], 1);
    expect(departments, hasLength(2));
    expect(departments.first.code, 'salon');
  });

  test('fetchDepartments falls back to appointment filters on 404', () async {
    adapter.enqueueJson(
      statusCode: 404,
      body: const <String, dynamic>{'message': 'Not Found'},
    );
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': const <dynamic>[],
        'meta': const <String, dynamic>{
          'current_page': 1,
          'last_page': 1,
          'total': 0,
        },
        'filters': const <String, dynamic>{
          'departments': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'code': 'salon', 'name': 'الصالون'},
            <String, dynamic>{'id': 2, 'code': 'clinic', 'name': 'العيادة'},
          ],
        },
      },
    );

    final departments = await repository.fetchDepartments();

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.uri.path, '/api/admin/departments');
    expect(adapter.requests.last.uri.path, '/api/admin/appointments');
    expect(adapter.requests.last.queryParameters['per_page'], 1);
    expect(departments, hasLength(2));
    expect(departments.last.code, 'clinic');
  });

  test('fetchCatalogItems supports all departments', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': const <Map<String, dynamic>>[
          <String, dynamic>{'id': 31, 'name': 'تنظيف بشرة', 'type': 'service'},
        ],
      },
    );

    final items = await repository.fetchCatalogItems();
    final RequestOptions request = adapter.requests.single;

    expect(request.uri.path, '/api/admin/catalog-items');
    expect(request.queryParameters.containsKey('department'), isFalse);
    expect(items.single.id, 31);
  });

  test('createCoupon posts JSON payload', () async {
    adapter.enqueueJson(
      statusCode: 201,
      body: <String, dynamic>{'data': _couponJson(id: 21)},
    );

    final coupon = await repository.createCoupon(const <String, dynamic>{
      'name': 'خصم جديد',
      'code': 'NEW20',
      'discount_type': 'percentage',
      'discount_value': 20,
      'maximum_uses_per_customer': 1,
      'catalog_item_ids': <int>[],
    });

    final RequestOptions request = adapter.requests.single;

    expect(request.method, 'POST');
    expect(request.uri.path, '/api/admin/coupons');
    expect((request.data as Map<String, dynamic>)['code'], 'NEW20');
    expect(coupon.id, 21);
  });

  test('updateCoupon uses patch endpoint', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{'data': _couponJson(id: 31)},
    );

    await repository.updateCoupon(
      couponId: 31,
      fields: const <String, dynamic>{
        'name': 'خصم محدث',
        'code': 'UPDATED',
        'discount_type': 'fixed',
        'discount_value': 10000,
        'maximum_uses_per_customer': 1,
        'is_active': true,
        'catalog_item_ids': <int>[],
      },
    );

    final RequestOptions request = adapter.requests.single;

    expect(request.method, 'PATCH');
    expect(request.uri.path, '/api/admin/coupons/31');
  });

  test('deleteCoupon parses deactivation result', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: const <String, dynamic>{
        'message': 'تم تعطيل الكوبون بدل حذفه.',
        'deleted': false,
        'deactivated': true,
      },
    );

    final result = await repository.deleteCoupon(41);

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.uri.path, '/api/admin/coupons/41');
    expect(result.deleted, isFalse);
    expect(result.deactivated, isTrue);
  });
}

Map<String, dynamic> _couponJson({required int id}) {
  return <String, dynamic>{
    'id': id,
    'name': 'خصم الترحيب',
    'code': 'WELCOME20',
    'discount_type': 'percentage',
    'discount_value': 20,
    'minimum_order_amount': 50000,
    'maximum_discount_amount': 25000,
    'department_id': 1,
    'department': const <String, dynamic>{'id': 1, 'name': 'الصالون'},
    'maximum_total_uses': 100,
    'maximum_uses_per_customer': 1,
    'used_count': 4,
    'remaining_uses': 96,
    'starts_at': '2026-07-01T00:00:00.000000Z',
    'expires_at': '2027-08-01T00:00:00.000000Z',
    'is_active': true,
    'is_available': true,
    'notes': null,
    'catalog_item_ids': const <int>[31],
  };
}

class _QueueAdapter implements HttpClientAdapter {
  final Queue<_QueuedResponse> _responses = Queue<_QueuedResponse>();
  final List<RequestOptions> requests = <RequestOptions>[];

  void enqueueJson({required int statusCode, required Object body}) {
    _responses.add(
      _QueuedResponse(
        statusCode: statusCode,
        body: jsonEncode(body),
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (requestStream != null) {
      await requestStream.drain<void>();
    }

    if (_responses.isEmpty) {
      throw StateError('No queued response is available.');
    }

    final _QueuedResponse response = _responses.removeFirst();

    return ResponseBody.fromString(
      response.body,
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _QueuedResponse {
  const _QueuedResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;
}
