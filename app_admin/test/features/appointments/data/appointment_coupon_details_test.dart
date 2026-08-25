import 'package:app_admin/features/appointments/data/appointment_details_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin appointment details exposes coupon summary', () {
    final details = AppointmentDetails.fromJson(<String, dynamic>{
      'id': 21,
      'reference': 'GL-TEST-21',
      'status': 'pending',
      'customer': <String, dynamic>{
        'id': 7,
        'name': 'زبونة الاختبار',
        'phone': '07700000000',
        'email': 'customer@example.test',
        'is_active': true,
      },
      'department': <String, dynamic>{
        'id': 1,
        'code': 'salon',
        'name': 'الصالون',
      },
      'coupon': <String, dynamic>{'id': 3, 'code': 'VIP20', 'name': 'خصم VIP'},
      'subtotal_amount': '100000.00',
      'discount_amount': '20000.00',
      'final_amount': '80000.00',
      'requested_start_at': '2026-07-30T12:00:00Z',
      'confirmed_start_at': null,
      'customer_notes': 'ملاحظة الزبونة',
      'admin_notes': null,
      'cancelled_by': null,
      'cancellation_reason': null,
      'cancelled_at': null,
      'completed_at': null,
      'no_show_at': null,
      'items': const <dynamic>[],
      'created_at': '2026-07-30T11:00:00Z',
      'updated_at': '2026-07-30T11:00:00Z',
    });

    expect(details.customerNotes, contains('VIP20'));
    expect(details.customerNotes, contains('20,000 د.ع'));
    expect(details.customerNotes, contains('80,000 د.ع'));
    expect(details.customerNotes, contains('ملاحظة الزبونة'));
  });
}
