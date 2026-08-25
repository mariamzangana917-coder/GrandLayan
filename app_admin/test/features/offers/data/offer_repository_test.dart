import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_admin/core/network/api_exception.dart';
import 'package:app_admin/features/offers/data/offer_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late _QueueAdapter adapter;
  late OfferApiRepository repository;
  late Directory tempDirectory;

  setUp(() async {
    adapter = _QueueAdapter();
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://example.test/api',
        headers: const <String, dynamic>{'Accept': 'application/json'},
      ),
    )..httpClientAdapter = adapter;

    repository = OfferApiRepository(dio: dio);
    tempDirectory = await Directory.systemTemp.createTemp(
      'grand_layan_offer_repository_test_',
    );
  });

  tearDown(() async {
    dio.close(force: true);

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('fetchOffers sends filters and parses Laravel pagination', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': <Map<String, dynamic>>[_offerJson(id: 11, title: 'عرض VIP')],
        'meta': <String, dynamic>{
          'current_page': 2,
          'last_page': 4,
          'total': 64,
        },
      },
    );

    final page = await repository.fetchOffers(
      search: 'VIP',
      department: 'salon',
      availability: 'current',
      isActive: true,
      page: 2,
    );

    expect(adapter.requests, hasLength(1));

    final request = adapter.requests.single;

    expect(request.method, 'GET');
    expect(request.uri.path, '/api/admin/offers');
    expect(request.queryParameters['search'], 'VIP');
    expect(request.queryParameters['department'], 'salon');
    expect(request.queryParameters['availability'], 'current');
    expect(request.queryParameters['is_active'], 1);
    expect(request.queryParameters['page'], 2);
    expect(request.queryParameters['per_page'], 20);

    expect(page.items, hasLength(1));
    expect(page.items.single.id, 11);
    expect(page.items.single.title, 'عرض VIP');
    expect(page.currentPage, 2);
    expect(page.lastPage, 4);
    expect(page.total, 64);
    expect(page.hasMore, isTrue);
  });

  test('fetchOffers omits empty optional filters', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': const <dynamic>[],
        'meta': const <String, dynamic>{
          'current_page': 1,
          'last_page': 1,
          'total': 0,
        },
      },
    );

    await repository.fetchOffers(
      search: '   ',
      department: '',
      availability: null,
    );

    final query = adapter.requests.single.queryParameters;

    expect(query.containsKey('search'), isFalse);
    expect(query.containsKey('department'), isFalse);
    expect(query.containsKey('availability'), isFalse);
    expect(query.containsKey('is_active'), isFalse);
  });

  test('fetchDepartments requests active admin departments', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'code': 'salon', 'name': 'الصالون'},
          <String, dynamic>{'id': 2, 'code': 'clinic', 'name': 'العيادة'},
        ],
      },
    );

    final departments = await repository.fetchDepartments();

    final request = adapter.requests.single;

    expect(request.method, 'GET');
    expect(request.uri.path, '/api/admin/departments');
    expect(request.queryParameters['is_active'], 1);
    expect(request.queryParameters['per_page'], 100);

    expect(departments, hasLength(2));
    expect(departments.first.code, 'salon');
    expect(departments.last.name, 'العيادة');
  });

  test('fetchCatalogItems filters by department and active status', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 31,
            'name': 'تنظيف بشرة ملكي',
            'type': 'service',
            'price_type': 'fixed',
            'price': '25000.00',
            'duration_minutes': 45,
            'is_active': true,
          },
        ],
      },
    );

    final items = await repository.fetchCatalogItems(departmentCode: 'salon');

    final request = adapter.requests.single;

    expect(request.method, 'GET');
    expect(request.uri.path, '/api/admin/catalog-items');
    expect(request.queryParameters['department'], 'salon');
    expect(request.queryParameters['is_active'], 1);
    expect(request.queryParameters['per_page'], 100);

    expect(items, hasLength(1));
    expect(items.single.id, 31);
    expect(items.single.name, 'تنظيف بشرة ملكي');
  });

  test('createOffer sends multipart data and parses created offer', () async {
    final image = await _createFakeImage(tempDirectory, 'offer-create.png');

    adapter.enqueueJson(
      statusCode: 201,
      body: <String, dynamic>{'data': _offerJson(id: 41, title: 'عرض جديد')},
    );

    final offer = await repository.createOffer(
      fields: <String, dynamic>{
        'department_id': 1,
        'catalog_item_id': null,
        'title': 'عرض جديد',
        'starts_at': '2026-07-29T09:00:00.000Z',
        'ends_at': '2026-08-05T09:00:00.000Z',
        'is_active': true,
        'sort_order': 0,
      },
      imagePath: image.path,
    );

    final request = adapter.requests.single;

    expect(request.method, 'POST');
    expect(request.uri.path, '/api/admin/offers');
    expect(request.data, isA<FormData>());

    final formData = request.data as FormData;
    final fields = Map<String, String>.fromEntries(formData.fields);

    expect(fields['department_id'], '1');
    expect(fields['title'], 'عرض جديد');
    expect(fields['is_active'], '1');
    expect(fields['sort_order'], '0');
    expect(formData.files, hasLength(1));
    expect(formData.files.single.key, 'image');
    expect(formData.files.single.value.filename, 'offer-create.png');

    expect(offer.id, 41);
    expect(offer.title, 'عرض جديد');
  });

  test('updateOffer sends patch request with metadata', () async {
    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': _offerJson(id: 51, title: 'العرض المعدل'),
      },
    );

    final offer = await repository.updateOffer(
      offerId: 51,
      fields: const <String, dynamic>{
        'title': 'العرض المعدل',
        'is_active': false,
      },
    );

    final request = adapter.requests.single;

    expect(request.method, 'PATCH');
    expect(request.uri.path, '/api/admin/offers/51');
    expect(request.data, isA<Map<String, dynamic>>());

    final body = Map<String, dynamic>.from(request.data as Map);

    expect(body['title'], 'العرض المعدل');
    expect(body['is_active'], isFalse);
    expect(offer.id, 51);
    expect(offer.title, 'العرض المعدل');
  });

  test('replaceImage posts multipart image to dedicated endpoint', () async {
    final image = await _createFakeImage(
      tempDirectory,
      'offer-replacement.png',
    );

    adapter.enqueueJson(
      statusCode: 200,
      body: <String, dynamic>{
        'data': _offerJson(id: 61, title: 'عرض بصورة جديدة'),
      },
    );

    final offer = await repository.replaceImage(
      offerId: 61,
      imagePath: image.path,
    );

    final request = adapter.requests.single;

    expect(request.method, 'POST');
    expect(request.uri.path, '/api/admin/offers/61/image');
    expect(request.data, isA<FormData>());

    final formData = request.data as FormData;

    expect(formData.files, hasLength(1));
    expect(formData.files.single.key, 'image');
    expect(formData.files.single.value.filename, 'offer-replacement.png');
    expect(offer.id, 61);
  });

  test('deleteOffer sends delete request to selected offer', () async {
    adapter.enqueueEmpty(statusCode: 204);

    await repository.deleteOffer(71);

    final request = adapter.requests.single;

    expect(request.method, 'DELETE');
    expect(request.uri.path, '/api/admin/offers/71');
  });

  test('maps validation response into ApiException', () async {
    final image = await _createFakeImage(tempDirectory, 'invalid-offer.png');

    adapter.enqueueJson(
      statusCode: 422,
      body: const <String, dynamic>{
        'message': 'The given data was invalid.',
        'errors': <String, dynamic>{
          'title': <String>['عنوان العرض مطلوب.'],
        },
      },
    );

    await expectLater(
      repository.createOffer(
        fields: const <String, dynamic>{
          'department_id': 1,
          'title': '',
          'starts_at': '2026-07-29T09:00:00.000Z',
          'ends_at': '2026-08-05T09:00:00.000Z',
          'is_active': true,
          'sort_order': 0,
        },
        imagePath: image.path,
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.firstErrorFor('title'),
              'title validation error',
              'عنوان العرض مطلوب.',
            ),
      ),
    );
  });
}

Map<String, dynamic> _offerJson({required int id, required String title}) {
  return <String, dynamic>{
    'id': id,
    'department': const <String, dynamic>{
      'id': 1,
      'code': 'salon',
      'name': 'الصالون',
    },
    'catalog_item': null,
    'title': title,
    'description': 'وصف العرض',
    'badge_text': 'VIP',
    'value_text': 'خصم 20%',
    'details_text': 'لفترة محدودة',
    'image_url': 'http://example.test/storage/offers/offer-$id.png',
    'starts_at': '2026-07-29T09:00:00.000000Z',
    'ends_at': '2026-08-05T09:00:00.000000Z',
    'is_active': true,
    'sort_order': 0,
    'availability': 'current',
  };
}

Future<File> _createFakeImage(Directory directory, String name) async {
  final file = File('${directory.path}${Platform.pathSeparator}$name');

  return file.writeAsBytes(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ], flush: true);
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

  void enqueueEmpty({required int statusCode}) {
    _responses.add(
      _QueuedResponse(
        statusCode: statusCode,
        body: '',
        headers: const <String, List<String>>{},
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

    // Consume multipart request streams so Windows releases image file handles.
    if (requestStream != null) {
      await requestStream.drain<void>();
    }

    if (_responses.isEmpty) {
      throw StateError('No queued response is available.');
    }

    final response = _responses.removeFirst();

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
