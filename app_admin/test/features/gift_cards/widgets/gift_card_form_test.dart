import 'package:app_admin/features/gift_cards/widgets/gift_card_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('validates required and numeric fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: GiftCardForm(isDarkMode: false, onSubmit: (_) async {}),
          ),
        ),
      ),
    );

    final Finder submitButton = find.byKey(
      const ValueKey<String>('gift-card-submit'),
    );

    await tester.dragUntilVisible(
      submitButton,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('هذا الحقل مطلوب.'), findsOneWidget);
    expect(find.text('أدخلي رقمًا أكبر من صفر.'), findsOneWidget);
  });

  testWidgets('submits valid gift card data', (WidgetTester tester) async {
    GiftCardFormData? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: GiftCardForm(
              isDarkMode: false,
              onSubmit: (GiftCardFormData data) async {
                submitted = data;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('gift-card-name')),
      'البطاقة الذهبية',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('gift-card-description')),
      'هدية مميزة',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('gift-card-amount')),
      '100000',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('gift-card-validity')),
      '60',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('gift-card-sort-order')),
      '2',
    );

    final Finder submitButton = find.byKey(
      const ValueKey<String>('gift-card-submit'),
    );

    await tester.dragUntilVisible(
      submitButton,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.name, 'البطاقة الذهبية');
    expect(submitted!.description, 'هدية مميزة');
    expect(submitted!.amount, 100000);
    expect(submitted!.validityDays, 60);
    expect(submitted!.sortOrder, 2);
    expect(submitted!.isActive, isTrue);
    expect(submitted!.imageFilePath, isNull);
  });
}
