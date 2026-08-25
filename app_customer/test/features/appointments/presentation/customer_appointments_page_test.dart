import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_customer/features/appointments/data/models/customer_appointment.dart';
import 'package:app_customer/features/appointments/presentation/customer_appointments_page.dart';
import 'package:app_customer/features/appointments/providers/appointment_provider.dart';

class FakeCustomerAppointmentsNotifier
    extends CustomerAppointmentsNotifier {
  FakeCustomerAppointmentsNotifier(this._initialData);

  final List<CustomerAppointment> _initialData;

  @override
  Future<List<CustomerAppointment>> build() async {
    return _initialData;
  }
}

void main() {
  testWidgets('CustomerAppointmentsPage displays empty state when no appointments', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerAppointmentsProvider.overrideWith(
            () => FakeCustomerAppointmentsNotifier([]),
          ),
        ],
        child: const MaterialApp(
          home: CustomerAppointmentsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('مواعيدي'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('القادمة والنشطة'), findsOneWidget);
    expect(find.text('السابقة والملغاة'), findsOneWidget);
    expect(find.text('لا توجد مواعيد قادمة'), findsOneWidget);
    expect(find.text('حجز في الصالون'), findsOneWidget);
    expect(find.text('حجز في العيادة'), findsOneWidget);
  });

  testWidgets('CustomerAppointmentsPage displays real appointment cards', (tester) async {
    final sampleAppointment = CustomerAppointment.fromJson({
      'id': 1,
      'reference': 'GL-20260822-DEMO1',
      'department': {
        'id': 1,
        'code': 'salon',
        'name': 'صالون',
      },
      'status': 'confirmed',
      'subtotal_amount': '50000.00',
      'discount_amount': '0.00',
      'final_amount': '50000.00',
      'requested_start_at': '2026-08-25T10:00:00.000Z',
      'confirmed_start_at': '2026-08-25T10:00:00.000Z',
      'items': [
        {
          'id': 10,
          'catalog_item_id': 1,
          'item_type': 'service',
          'item_name': 'قص شعر فاخر',
          'price_type': 'fixed',
          'unit_price': '50000.00',
          'quantity': 1,
          'duration_minutes': 30,
          'services': [],
        },
      ],
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerAppointmentsProvider.overrideWith(
            () => FakeCustomerAppointmentsNotifier([sampleAppointment]),
          ),
        ],
        child: const MaterialApp(
          home: CustomerAppointmentsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('مواعيدي'), findsOneWidget);
    expect(find.text('GL-20260822-DEMO1'), findsOneWidget);
    expect(find.text('قص شعر فاخر'), findsOneWidget);
    expect(find.text('مؤكد'), findsOneWidget);
    expect(find.text('عرض التفاصيل'), findsOneWidget);
  });
}
