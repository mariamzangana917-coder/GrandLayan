import 'package:app_admin/features/offers/data/admin_offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminOffer', () {
    test('parses a complete offer response', () {
      final offer = AdminOffer.fromJson(<String, dynamic>{
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
        'starts_at': '2026-07-29T09:00:00.000000Z',
        'ends_at': '2026-08-05T09:00:00.000000Z',
        'is_active': true,
        'sort_order': 3,
        'availability': 'current',
      });

      expect(offer.id, 14);
      expect(offer.department.id, 1);
      expect(offer.department.code, 'salon');
      expect(offer.department.name, 'الصالون');
      expect(offer.catalogItem?.id, 8);
      expect(offer.catalogItem?.name, 'تنظيف بشرة ملكي');
      expect(offer.catalogItem?.price, '25000.00');
      expect(offer.title, 'عرض العناية');
      expect(offer.description, 'وصف العرض');
      expect(offer.badgeText, 'VIP');
      expect(offer.valueText, 'خصم 20%');
      expect(offer.detailsText, 'لفترة محدودة');
      expect(offer.isActive, isTrue);
      expect(offer.sortOrder, 3);
      expect(offer.availability, 'current');
      expect(offer.startsAt.isUtc, isTrue);
      expect(offer.endsAt.isUtc, isTrue);
    });

    test('allows an offer without a linked catalog item', () {
      final offer = AdminOffer.fromJson(<String, dynamic>{
        'id': 15,
        'department': <String, dynamic>{
          'id': 2,
          'code': 'clinic',
          'name': 'العيادة',
        },
        'catalog_item': null,
        'title': 'عرض العيادة',
        'description': null,
        'badge_text': null,
        'value_text': null,
        'details_text': null,
        'image_url': null,
        'starts_at': '2026-07-29T09:00:00Z',
        'ends_at': '2026-08-05T09:00:00Z',
        'is_active': 1,
        'sort_order': '0',
        'availability': 'current',
      });

      expect(offer.catalogItem, isNull);
      expect(offer.description, isNull);
      expect(offer.badgeText, isNull);
      expect(offer.valueText, isNull);
      expect(offer.detailsText, isNull);
      expect(offer.imageUrl, isNull);
      expect(offer.isActive, isTrue);
      expect(offer.sortOrder, 0);
    });
  });

  group('AdminOfferPage', () {
    test('parses Laravel pagination metadata', () {
      final page = AdminOfferPage.fromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'department': <String, dynamic>{
              'id': 1,
              'code': 'salon',
              'name': 'الصالون',
            },
            'catalog_item': null,
            'title': 'عرض واحد',
            'starts_at': '2026-07-29T09:00:00Z',
            'ends_at': '2026-08-05T09:00:00Z',
            'is_active': true,
            'sort_order': 0,
            'availability': 'current',
          },
        ],
        'meta': <String, dynamic>{
          'current_page': 1,
          'last_page': 2,
          'total': 21,
        },
      });

      expect(page.items, hasLength(1));
      expect(page.currentPage, 1);
      expect(page.lastPage, 2);
      expect(page.total, 21);
      expect(page.hasMore, isTrue);
    });
  });
}
