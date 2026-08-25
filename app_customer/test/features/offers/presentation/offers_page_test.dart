import 'package:app_customer/features/offers/data/customer_offer.dart';
import 'package:app_customer/features/offers/data/customer_offer_repository.dart';
import 'package:app_customer/features/offers/presentation/offers_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads real offers and filters by department', (tester) async {
    final _FakeRepository repository = _FakeRepository();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const <Locale>[Locale('ar')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: OffersPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عرض متصل بالإدارة'), findsOneWidget);

    await tester.tap(find.text('الصالون').first);
    await tester.pumpAndSettle();

    expect(repository.lastDepartment, 'salon');
  });
}

class _FakeRepository implements CustomerOfferRepository {
  String? lastDepartment;

  @override
  Future<List<CustomerOffer>> fetchOffers({String? department}) async {
    lastDepartment = department;
    return <CustomerOffer>[
      CustomerOffer(
        id: 1,
        department: const CustomerOfferDepartment(
          id: 1,
          code: 'salon',
          name: 'الصالون',
        ),
        title: 'عرض متصل بالإدارة',
        description: 'وصف العرض',
        valueText: 'خصم 20%',
        startsAt: DateTime.utc(2026, 7, 29),
        endsAt: DateTime.utc(2026, 8, 5),
        availability: 'current',
      ),
    ];
  }
}
