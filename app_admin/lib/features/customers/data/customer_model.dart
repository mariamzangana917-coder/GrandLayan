class CustomerListResponse {
  const CustomerListResponse({
    required this.customers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminCustomer> customers;
  final int currentPage;
  final int lastPage;
  final int total;

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawMeta = json['meta'];

    final customers = <AdminCustomer>[];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map) {
          customers.add(
            AdminCustomer.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    return CustomerListResponse(
      customers: customers,
      currentPage: _toInt(meta['current_page'], fallback: 1),
      lastPage: _toInt(meta['last_page'], fallback: 1),
      total: _toInt(meta['total'], fallback: customers.length),
    );
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class AdminCustomer {
  const AdminCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.avatar,
    required this.isActive,
    required this.appointmentsCount,
    required this.lastAppointmentAt,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatar;
  final bool isActive;
  final int appointmentsCount;
  final DateTime? lastAppointmentAt;
  final DateTime? createdAt;

  factory AdminCustomer.fromJson(Map<String, dynamic> json) {
    return AdminCustomer(
      id: CustomerListResponse._toInt(json['id'], fallback: 0),
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : 'عميلة',
      phone: _nullableText(json['phone']),
      email: _nullableText(json['email']),
      avatar: _nullableText(json['avatar']),
      isActive: _toBool(json['is_active']),
      appointmentsCount: CustomerListResponse._toInt(
        json['appointments_count'] ?? json['appointment_count'],
        fallback: 0,
      ),
      lastAppointmentAt: _toDateTime(
        json['last_appointment_at'] ?? json['latest_appointment_at'],
      ),
      createdAt: _toDateTime(json['created_at']),
    );
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase();

    return text == '1' || text == 'true';
  }

  static DateTime? _toDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
