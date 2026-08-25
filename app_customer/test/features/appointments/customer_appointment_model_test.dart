import 'package:flutter_test/flutter_test.dart';
import 'package:app_customer/features/appointments/data/models/customer_appointment.dart';

void main() {
  group('CustomerAppointment Model Tests', () {
    test('Correctly deserializes list response from Backend JSON', () {
      final json = {
        'data': [
          {
            'id': 10,
            'reference': 'GL-20260822-ABC12345',
            'customer': {
              'id': 5,
              'name': 'مريم زنكنة',
              'phone': '07701234567',
            },
            'department': {
              'id': 1,
              'code': 'salon',
              'name': 'صالون',
            },
            'coupon': {
              'id': 2,
              'name': 'خصم خاص',
              'code': 'SUMMER20',
              'discount_type': 'percentage',
              'discount_value': 20.0,
            },
            'subtotal_amount': '100000.00',
            'discount_amount': '20000.00',
            'final_amount': '80000.00',
            'status': 'pending',
            'requested_start_at': '2026-08-25T14:30:00.000000Z',
            'confirmed_start_at': null,
            'customer_notes': 'يرجى تجهيز غرفة خاصة',
            'cancelled_by': null,
            'cancellation_reason': null,
            'cancelled_at': null,
            'items': [
              {
                'id': 1,
                'catalog_item_id': 15,
                'item_type': 'package',
                'item_name': 'باقة العناية الملكية',
                'price_type': 'fixed',
                'unit_price': '100000.00',
                'quantity': 1,
                'duration_minutes': 90,
                'services': [
                  {
                    'id': 101,
                    'service_id': 20,
                    'service_name': 'تنظيف بشرة ملكي',
                    'quantity': 1,
                    'duration_minutes': 45,
                    'unit_price': null,
                    'scheduled_start_at': null,
                    'scheduled_end_at': null,
                    'notes': 'خدمة أولى',
                  },
                  {
                    'id': 102,
                    'service_id': 21,
                    'service_name': 'مساج استرخائي',
                    'quantity': 1,
                    'duration_minutes': 45,
                    'unit_price': null,
                    'scheduled_start_at': null,
                    'scheduled_end_at': null,
                    'notes': null,
                  },
                ],
              },
            ],
            'created_at': '2026-08-22T10:00:00.000000Z',
            'updated_at': '2026-08-22T10:00:00.000000Z',
          }
        ],
        'meta': {
          'current_page': 1,
          'last_page': 2,
          'per_page': 15,
          'total': 25,
        },
      };

      final response = CustomerAppointmentListResponse.fromJson(json);

      expect(response.currentPage, 1);
      expect(response.lastPage, 2);
      expect(response.perPage, 15);
      expect(response.total, 25);
      expect(response.hasMorePages, isTrue);
      expect(response.appointments.length, 1);

      final appointment = response.appointments.first;
      expect(appointment.id, 10);
      expect(appointment.reference, 'GL-20260822-ABC12345');
      expect(appointment.department.code, 'salon');
      expect(appointment.department.name, 'صالون');
      expect(appointment.department.isSalon, isTrue);
      expect(appointment.department.isClinic, isFalse);

      expect(appointment.status, 'pending');
      expect(appointment.statusLabel, 'قيد المراجعة');
      expect(appointment.isUpcoming, isTrue);
      expect(appointment.isPast, isFalse);
      expect(appointment.canBeCancelled, isTrue);

      expect(appointment.coupon?.code, 'SUMMER20');
      expect(appointment.subtotalAmount, 100000.0);
      expect(appointment.discountAmount, 20000.0);
      expect(appointment.finalAmount, 80000.0);

      expect(appointment.items.length, 1);
      final item = appointment.items.first;
      expect(item.isPackage, isTrue);
      expect(item.itemName, 'باقة العناية الملكية');
      expect(item.services.length, 2);
      expect(item.services[0].serviceName, 'تنظيف بشرة ملكي');
      expect(item.services[1].serviceName, 'مساج استرخائي');
      expect(appointment.totalDurationMinutes, 90);
    });

    test('Checks status categories and helpers', () {
      final pendingAppointment = CustomerAppointment.fromJson({
        'id': 1,
        'reference': 'GL-1',
        'status': 'pending',
        'items': [],
      });
      expect(pendingAppointment.isUpcoming, isTrue);
      expect(pendingAppointment.isPast, isFalse);
      expect(pendingAppointment.canBeCancelled, isTrue);
      expect(pendingAppointment.statusLabel, 'قيد المراجعة');

      final confirmedAppointment = CustomerAppointment.fromJson({
        'id': 2,
        'reference': 'GL-2',
        'status': 'confirmed',
        'items': [],
      });
      expect(confirmedAppointment.isUpcoming, isTrue);
      expect(confirmedAppointment.isPast, isFalse);
      expect(confirmedAppointment.canBeCancelled, isTrue);
      expect(confirmedAppointment.statusLabel, 'مؤكد');

      final inProgressAppointment = CustomerAppointment.fromJson({
        'id': 3,
        'reference': 'GL-3',
        'status': 'in_progress',
        'items': [],
      });
      expect(inProgressAppointment.isUpcoming, isTrue);
      expect(inProgressAppointment.isPast, isFalse);
      expect(inProgressAppointment.canBeCancelled, isFalse);
      expect(inProgressAppointment.statusLabel, 'جاري التنفيذ');

      final completedAppointment = CustomerAppointment.fromJson({
        'id': 4,
        'reference': 'GL-4',
        'status': 'completed',
        'items': [],
      });
      expect(completedAppointment.isUpcoming, isFalse);
      expect(completedAppointment.isPast, isTrue);
      expect(completedAppointment.canBeCancelled, isFalse);
      expect(completedAppointment.statusLabel, 'مكتمل');

      final cancelledAppointment = CustomerAppointment.fromJson({
        'id': 5,
        'reference': 'GL-5',
        'status': 'cancelled',
        'cancelled_by': 'customer',
        'items': [],
      });
      expect(cancelledAppointment.isUpcoming, isFalse);
      expect(cancelledAppointment.isPast, isTrue);
      expect(cancelledAppointment.canBeCancelled, isFalse);
      expect(cancelledAppointment.statusLabel, 'ملغي');
      expect(cancelledAppointment.statusDescription, contains('بناءً على طلبكِ'));
    });
  });
}
