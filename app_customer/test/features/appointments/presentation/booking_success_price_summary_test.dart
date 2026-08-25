import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_customer/features/appointments/presentation/widgets/booking_success_price_summary.dart';

void main() {
  testWidgets('shows confirmed coupon totals to customer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BookingSuccessPriceSummary(
              reference: 'GL-1001',
              appointmentData: <String, dynamic>{
                'coupon': <String, dynamic>{'code': 'VIP20', 'name': 'خصم VIP'},
                'subtotal_amount': '100000.00',
                'discount_amount': '20000.00',
                'final_amount': '80000.00',
              },
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('GL-1001'), findsOneWidget);
    expect(find.text('VIP20'), findsOneWidget);
    expect(find.text('100,000 د.ع'), findsOneWidget);
    expect(find.text('- 20,000 د.ع'), findsOneWidget);
    expect(find.text('80,000 د.ع'), findsOneWidget);
  });

  testWidgets('shows final amount without fake coupon details', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BookingSuccessPriceSummary(
              reference: '',
              appointmentData: <String, dynamic>{
                'subtotal_amount': '50000.00',
                'discount_amount': '0.00',
                'final_amount': '50000.00',
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('ملخص المبلغ'), findsOneWidget);
    expect(find.text('50,000 د.ع'), findsNWidgets(2));
    expect(find.text('كود الخصم'), findsNothing);
  });
}
