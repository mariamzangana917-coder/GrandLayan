import 'package:app_customer/features/catalog/data/models/catalog_item.dart';
import 'package:app_customer/features/salon/presentation/salon_service_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders service details without images', (
    WidgetTester tester,
  ) async {
    const CatalogItem item = CatalogItem(
      id: 1,
      name: 'قص الشعر',
      type: 'service',
      priceType: 'fixed',
      price: 25000,
      durationMinutes: 30,
      description: 'وصف الخدمة',
      instructions: 'تعليمات الخدمة',
      isActive: true,
      isFavorite: false,
    );

    await tester.pumpWidget(
      const MaterialApp(home: SalonServiceDetailsPage(item: item)),
    );

    await tester.pump();

    expect(find.text('قص الشعر'), findsOneWidget);
    expect(find.text('عن الخدمة'), findsOneWidget);
    expect(find.text('احجزي الآن'), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders inspection price safely', (WidgetTester tester) async {
    const CatalogItem item = CatalogItem(
      id: 2,
      name: 'صبغ الشعر',
      type: 'service',
      priceType: 'inspection',
      isActive: true,
      isFavorite: false,
    );

    await tester.pumpWidget(
      const MaterialApp(home: SalonServiceDetailsPage(item: item)),
    );

    await tester.pump();

    expect(find.text('صبغ الشعر'), findsOneWidget);
    expect(find.text('السعر بعد المعاينة'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
