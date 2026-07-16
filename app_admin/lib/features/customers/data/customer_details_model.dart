class CustomerDetails {
  const CustomerDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.createdAt,
    required this.appointmentsCount,
    required this.lastAppointmentAt,
    required this.appointments,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime? createdAt;
  final int appointmentsCount;
  final DateTime? lastAppointmentAt;
  final List<CustomerAppointmentSummary> appointments;

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    final items = <CustomerAppointmentSummary>[];
    final rawAppointments = json['appointments'];

    if (rawAppointments is List) {
      for (final item in rawAppointments) {
        if (item is Map) {
          items.add(
            CustomerAppointmentSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return CustomerDetails(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'عميلة',
      phone: _text(json['phone']),
      email: _text(json['email']),
      isActive: _bool(json['is_active']),
      createdAt: _date(json['created_at']),
      appointmentsCount: _toInt(json['appointments_count']),
      lastAppointmentAt: _date(json['last_appointment_at']),
      appointments: items,
    );
  }

  static int _toInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static bool _bool(dynamic value) =>
      value == true || value == 1 || value?.toString() == '1';

  static DateTime? _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');
}

class CustomerAppointmentSummary {
  const CustomerAppointmentSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.requestedStartAt,
  });

  final int id;
  final String reference;
  final String status;
  final DateTime? requestedStartAt;

  factory CustomerAppointmentSummary.fromJson(Map<String, dynamic> json) {
    return CustomerAppointmentSummary(
      id: CustomerDetails._toInt(json['id']),
      reference: json['reference']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      requestedStartAt: CustomerDetails._date(json['requested_start_at']),
    );
  }
}
