import 'package:app_customer/features/offers/data/customer_offer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository sends department and parses offers', () async {
    final _FakeDataSource source = _FakeDataSource();
    final CustomerOfferApiRepository repository = CustomerOfferApiRepository(
      dataSource: source,
    );

    final offers = await repository.fetchOffers(department: 'salon');

    expect(source.department, 'salon');
    expect(offers, hasLength(1));
    expect(offers.single.title, 'عرض الصالون');
  });
}

class _FakeDataSource implements CustomerOfferDataSource {
  String? department;

  @override
  Future<Map<String, dynamic>> fetchOffers({String? department}) async {
    this.department = department;
    return <String, dynamic>{
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'department': <String, dynamic>{
            'id': 1,
            'code': 'salon',
            'name': 'الصالون',
          },
          'catalog_item': null,
          'title': 'عرض الصالون',
          'image_url': null,
          'starts_at': '2026-07-29T09:00:00Z',
          'ends_at': '2026-08-05T09:00:00Z',
          'availability': 'current',
        },
      ],
    };
  }
}
