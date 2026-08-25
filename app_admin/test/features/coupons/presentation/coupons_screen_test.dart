import 'package:app_admin/features/coupons/data/admin_coupon.dart';
import 'package:app_admin/features/coupons/data/coupon_repository.dart';
import 'package:app_admin/features/coupons/presentation/coupons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders coupon card with real usage data', (
    WidgetTester tester,
  ) async {
    final _FakeCouponRepository repository = _FakeCouponRepository(
      coupons: <AdminCoupon>[_coupon()],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME20'), findsOneWidget);
    expect(find.text('خصم الترحيب'), findsOneWidget);
    expect(find.text('20% خصم'), findsOneWidget);
    expect(find.text('مستخدم 4 من 100'), findsOneWidget);
    expect(find.text('متاح'), findsOneWidget);
  });

  testWidgets('search reloads coupons using typed code', (
    WidgetTester tester,
  ) async {
    final _FakeCouponRepository repository = _FakeCouponRepository(
      coupons: <AdminCoupon>[_coupon()],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'WELCOME');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.lastSearch, 'WELCOME');
  });

  testWidgets('availability chip reloads upcoming coupons', (
    WidgetTester tester,
  ) async {
    final _FakeCouponRepository repository = _FakeCouponRepository(
      coupons: <AdminCoupon>[_coupon()],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تبدأ قريبًا'));
    await tester.pumpAndSettle();

    expect(repository.lastAvailability, 'upcoming');
  });

  testWidgets('empty state keeps add coupon action visible', (
    WidgetTester tester,
  ) async {
    final _FakeCouponRepository repository = _FakeCouponRepository(
      coupons: const <AdminCoupon>[],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد كوبونات'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('add-coupon-button')),
      findsOneWidget,
    );
  });
}

Widget _app(CouponRepository repository) {
  return MaterialApp(
    home: CouponsScreen(isDarkMode: false, repository: repository),
  );
}

AdminCoupon _coupon() {
  return AdminCoupon(
    id: 1,
    name: 'خصم الترحيب',
    code: 'WELCOME20',
    discountType: 'percentage',
    discountValue: 20,
    minimumOrderAmount: 50000,
    maximumDiscountAmount: 25000,
    departmentId: 1,
    department: const CouponDepartment(id: 1, name: 'الصالون', code: 'salon'),
    maximumTotalUses: 100,
    maximumUsesPerCustomer: 1,
    usedCount: 4,
    remainingUses: 96,
    startsAt: DateTime(2026, 7, 1),
    expiresAt: DateTime(2027, 8, 1),
    isActive: true,
    isAvailable: true,
    notes: null,
    catalogItemIds: const <int>[31],
  );
}

class _FakeCouponRepository implements CouponRepository {
  _FakeCouponRepository({required this.coupons});

  final List<AdminCoupon> coupons;

  String? lastSearch;
  String? lastAvailability;

  @override
  Future<AdminCouponPage> fetchCoupons({
    String? search,
    int? departmentId,
    String? discountType,
    String? availability,
    bool? isActive,
    int page = 1,
  }) async {
    lastSearch = search;
    lastAvailability = availability;

    return AdminCouponPage(
      items: coupons,
      currentPage: 1,
      lastPage: 1,
      total: coupons.length,
    );
  }

  @override
  Future<List<CouponDepartment>> fetchDepartments() async {
    return const <CouponDepartment>[
      CouponDepartment(id: 1, name: 'الصالون', code: 'salon'),
      CouponDepartment(id: 2, name: 'العيادة', code: 'clinic'),
    ];
  }

  @override
  Future<AdminCoupon> fetchCoupon(int couponId) async {
    return coupons.firstWhere((AdminCoupon item) => item.id == couponId);
  }

  @override
  Future<List<CouponCatalogItem>> fetchCatalogItems({
    String? departmentCode,
  }) async {
    return const <CouponCatalogItem>[
      CouponCatalogItem(id: 31, name: 'تنظيف بشرة', type: 'service'),
    ];
  }

  @override
  Future<AdminCoupon> createCoupon(Map<String, dynamic> fields) async {
    return _coupon();
  }

  @override
  Future<AdminCoupon> updateCoupon({
    required int couponId,
    required Map<String, dynamic> fields,
  }) async {
    return _coupon();
  }

  @override
  Future<CouponDeleteResult> deleteCoupon(int couponId) async {
    return const CouponDeleteResult(
      message: 'تم حذف الكوبون بنجاح.',
      deleted: true,
      deactivated: false,
    );
  }
}
