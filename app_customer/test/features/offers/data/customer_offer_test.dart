import 'package:app_customer/features/offers/data/customer_offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses customer offer response', () {
    final CustomerOffer offer = CustomerOffer.fromJson(<String, dynamic>{
      'id': 14,
      'department': <String, dynamic>{
        'id': 1,
        'code': 'salon',
        'name': 'الصالون',
      },
      'catalog_item': <String, dynamic>{
        'id': 8,
        'name': 'تنظيف بشرة ملكي',
        'type': 'service',
        'price_type': 'fixed',
        'price': '25000.00',
        'duration_minutes': 45,
        'is_active': true,
      },
      'title': 'عرض العناية',
      'description': 'وصف العرض',
      'badge_text': 'VIP',
      'value_text': 'خصم 20%',
      'details_text': 'لفترة محدودة',
      'image_url': 'http://64.227.16.105/storage/offers/test.png',
      'starts_at': '2026-07-29T09:00:00Z',
      'ends_at': '2026-08-05T09:00:00Z',
      'availability': 'current',
    });

    expect(offer.id, 14);
    expect(offer.department.code, 'salon');
    expect(offer.catalogItem?.id, 8);
    expect(offer.title, 'عرض العناية');
    expect(offer.badgeText, 'VIP');
    expect(offer.valueText, 'خصم 20%');
    expect(offer.availability, 'current');
  });

  test('allows offer without linked catalog item', () {
    final CustomerOffer offer = CustomerOffer.fromJson(<String, dynamic>{
      'id': 15,
      'department': <String, dynamic>{
        'id': 2,
        'code': 'clinic',
        'name': 'العيادة',
      },
      'catalog_item': null,
      'title': 'عرض العيادة',
      'image_url': null,
      'starts_at': '2026-07-29T09:00:00Z',
      'ends_at': '2026-08-05T09:00:00Z',
      'availability': 'current',
    });

    expect(offer.catalogItem, isNull);
    expect(offer.department.code, 'clinic');
  });
}
