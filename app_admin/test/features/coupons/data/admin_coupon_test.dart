import 'package:app_admin/features/coupons/data/admin_coupon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses coupon response and derives available status', () {
    final AdminCoupon coupon = AdminCoupon.fromJson(<String, dynamic>{
      'id': 11,
      'name': 'خصم الترحيب',
      'code': 'WELCOME20',
      'discount_type': 'percentage',
      'discount_value': 20,
      'minimum_order_amount': 50000,
      'maximum_discount_amount': 25000,
      'department_id': 1,
      'department': <String, dynamic>{'id': 1, 'name': 'الصالون'},
      'maximum_total_uses': 100,
      'maximum_uses_per_customer': 1,
      'used_count': 4,
      'remaining_uses': 96,
      'starts_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toUtc()
          .toIso8601String(),
      'expires_at': DateTime.now()
          .add(const Duration(days: 7))
          .toUtc()
          .toIso8601String(),
      'is_active': true,
      'is_available': true,
      'notes': null,
      'catalog_item_ids': <int>[31, 32],
    });

    expect(coupon.id, 11);
    expect(coupon.department?.name, 'الصالون');
    expect(coupon.catalogItemIds, <int>[31, 32]);
    expect(coupon.availability, CouponAvailability.available);
  });

  test('inactive coupon wins over all date states', () {
    final AdminCoupon coupon = _coupon(
      isActive: false,
      startsAt: DateTime.now().add(const Duration(days: 5)),
    );

    expect(coupon.availability, CouponAvailability.inactive);
  });

  test('toPayload normalizes code and removes max for fixed discount', () {
    final AdminCoupon coupon = _coupon(
      discountType: 'fixed',
      maximumDiscountAmount: 25000,
    );

    final Map<String, dynamic> payload = coupon.toPayload(
      isActiveOverride: false,
    );

    expect(payload['code'], 'WELCOME20');
    expect(payload['maximum_discount_amount'], isNull);
    expect(payload['is_active'], isFalse);
    expect(payload['catalog_item_ids'], <int>[31]);
  });
}

AdminCoupon _coupon({
  String discountType = 'percentage',
  double? maximumDiscountAmount = 25000,
  bool isActive = true,
  DateTime? startsAt,
}) {
  return AdminCoupon(
    id: 1,
    name: 'خصم الترحيب',
    code: ' welcome20 ',
    discountType: discountType,
    discountValue: 20,
    minimumOrderAmount: 50000,
    maximumDiscountAmount: maximumDiscountAmount,
    departmentId: 1,
    department: const CouponDepartment(id: 1, name: 'الصالون', code: 'salon'),
    maximumTotalUses: 100,
    maximumUsesPerCustomer: 1,
    usedCount: 4,
    remainingUses: 96,
    startsAt: startsAt,
    expiresAt: DateTime.now().add(const Duration(days: 7)),
    isActive: isActive,
    isAvailable: true,
    notes: null,
    catalogItemIds: const <int>[31],
  );
}
