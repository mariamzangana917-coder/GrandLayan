import 'package:app_admin/features/offers/data/admin_offer.dart';
import 'package:app_admin/features/offers/data/offer_repository.dart';
import 'package:app_admin/features/offers/presentation/offers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows offers returned by repository', (tester) async {
    final repository = _FakeOfferRepository(
      pages: <AdminOfferPage>[
        AdminOfferPage(
          items: <AdminOffer>[
            _offer(
              id: 1,
              title: 'عرض VIP',
              valueText: 'خصم 20%',
              availability: 'current',
            ),
          ],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('إدارة العروض'), findsOneWidget);
    expect(find.text('عرض VIP'), findsOneWidget);
    expect(find.text('خصم 20%'), findsOneWidget);
    expect(find.text('متاح الآن'), findsOneWidget);
    expect(find.text('إضافة عرض'), findsOneWidget);
  });

  testWidgets('shows empty state when no offers exist', (tester) async {
    final repository = _FakeOfferRepository(
      pages: const <AdminOfferPage>[
        AdminOfferPage(
          items: <AdminOffer>[],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد عروض ضمن هذا الفلتر.'), findsOneWidget);
  });

  testWidgets('search field sends trimmed search to repository', (
    tester,
  ) async {
    final repository = _FakeOfferRepository(
      pages: const <AdminOfferPage>[
        AdminOfferPage(
          items: <AdminOffer>[],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
        AdminOfferPage(
          items: <AdminOffer>[],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '  عرائس  ');

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.searches.last, 'عرائس');
  });

  testWidgets('department filter reloads salon offers', (tester) async {
    final repository = _FakeOfferRepository(
      pages: const <AdminOfferPage>[
        AdminOfferPage(
          items: <AdminOffer>[],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
        AdminOfferPage(
          items: <AdminOffer>[],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('offers-department-selector')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('department-salon')));
    await tester.pumpAndSettle();

    expect(repository.departments.last, 'salon');
  });

  testWidgets('availability filter reloads current offers', (tester) async {
    final repository = _FakeOfferRepository(
      pages: const <AdminOfferPage>[
        AdminOfferPage(
          items: <AdminOffer>[],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
        AdminOfferPage(
          items: <AdminOffer>[],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الحالية'));
    await tester.pumpAndSettle();

    expect(repository.availabilities.last, 'current');
  });

  testWidgets('uses elegant label for upcoming offers', (tester) async {
    final repository = _FakeOfferRepository(
      pages: <AdminOfferPage>[
        AdminOfferPage(
          items: <AdminOffer>[
            _offer(
              id: 9,
              title: 'عرض العرائس',
              valueText: 'VIP',
              availability: 'upcoming',
            ),
          ],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('يبدأ قريبًا'), findsOneWidget);
    expect(find.text('قادم'), findsNothing);
  });

  testWidgets('retry button reloads after repository error', (tester) async {
    final repository = _FakeOfferRepository(
      errors: <Object>[Exception('connection failed')],
      pages: const <AdminOfferPage>[
        AdminOfferPage(
          items: <AdminOffer>[],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل العروض.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 2);
    expect(find.text('لا توجد عروض ضمن هذا الفلتر.'), findsOneWidget);
  });
}

Widget _buildApp(OfferRepository repository) {
  return MaterialApp(
    home: OffersScreen(isDarkMode: false, repository: repository),
  );
}

AdminOffer _offer({
  required int id,
  required String title,
  required String valueText,
  required String availability,
}) {
  return AdminOffer(
    id: id,
    department: const OfferDepartment(id: 1, code: 'salon', name: 'الصالون'),
    catalogItem: null,
    title: title,
    description: 'وصف العرض',
    badgeText: 'VIP',
    valueText: valueText,
    detailsText: 'لفترة محدودة',
    imageUrl: null,
    startsAt: DateTime(2026, 7, 29),
    endsAt: DateTime(2026, 8, 5),
    isActive: true,
    sortOrder: 0,
    availability: availability,
  );
}

class _FakeOfferRepository implements OfferRepository {
  _FakeOfferRepository({List<AdminOfferPage>? pages, List<Object>? errors})
    : _pages = List<AdminOfferPage>.from(pages ?? const <AdminOfferPage>[]),
      _errors = List<Object>.from(errors ?? const <Object>[]);

  final List<AdminOfferPage> _pages;
  final List<Object> _errors;

  final List<String?> searches = <String?>[];
  final List<String?> departments = <String?>[];
  final List<String?> availabilities = <String?>[];

  int fetchCount = 0;

  @override
  Future<AdminOfferPage> fetchOffers({
    String? search,
    String? department,
    String? availability,
    bool? isActive,
    int page = 1,
  }) async {
    fetchCount += 1;
    searches.add(search?.trim());
    departments.add(department);
    availabilities.add(availability);

    if (_errors.isNotEmpty) {
      throw _errors.removeAt(0);
    }

    if (_pages.isEmpty) {
      return const AdminOfferPage(
        items: <AdminOffer>[],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      );
    }

    return _pages.removeAt(0);
  }

  @override
  Future<List<OfferDepartment>> fetchDepartments() async {
    return const <OfferDepartment>[];
  }

  @override
  Future<List<OfferCatalogItem>> fetchCatalogItems({
    required String departmentCode,
  }) async {
    return const <OfferCatalogItem>[];
  }

  @override
  Future<AdminOffer> createOffer({
    required Map<String, dynamic> fields,
    required String imagePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AdminOffer> updateOffer({
    required int offerId,
    required Map<String, dynamic> fields,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AdminOffer> replaceImage({
    required int offerId,
    required String imagePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteOffer(int offerId) async {}
}
