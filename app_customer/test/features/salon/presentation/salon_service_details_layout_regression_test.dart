import 'package:app_customer/features/catalog/data/models/catalog_item.dart';
import 'package:app_customer/features/salon/presentation/salon_service_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('details page survives an infinite-width elevated button theme', (
    WidgetTester tester,
  ) async {
    const CatalogItem item = CatalogItem(
      id: 101,
      name: 'قص الشعر',
      type: 'service',
      priceType: 'fixed',
      price: 25000,
      durationMinutes: 30,
      description: 'وصف الخدمة',
      isActive: true,
      isFavorite: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
        ),
        home: const SalonServiceDetailsPage(item: item),
      ),
    );

    await tester.pump();

    expect(find.text('قص الشعر'), findsOneWidget);
    expect(find.text('احجزي الآن'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
