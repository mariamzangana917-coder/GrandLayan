class AppointmentDetails {
  const AppointmentDetails({
    required this.id,
    required this.reference,
    required this.status,
    required this.customer,
    required this.department,
    required this.requestedStartAt,
    required this.confirmedStartAt,
    required this.customerNotes,
    required this.adminNotes,
    required this.cancelledBy,
    required this.cancellationReason,
    required this.cancelledAt,
    required this.completedAt,
    required this.noShowAt,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String reference;
  final String status;
  final AppointmentCustomer customer;
  final AppointmentDepartment department;
  final DateTime? requestedStartAt;
  final DateTime? confirmedStartAt;
  final String? customerNotes;
  final String? adminNotes;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime? noShowAt;
  final List<AppointmentDetailsItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppointmentDetails.fromJson(Map<String, dynamic> json) {
    final rawCustomer = json['customer'];
    final rawDepartment = json['department'];
    final rawItems = json['items'];

    final customer = rawCustomer is Map
        ? AppointmentCustomer.fromJson(Map<String, dynamic>.from(rawCustomer))
        : const AppointmentCustomer.empty();

    final department = rawDepartment is Map
        ? AppointmentDepartment.fromJson(
            Map<String, dynamic>.from(rawDepartment),
          )
        : const AppointmentDepartment.empty();

    final items = <AppointmentDetailsItem>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(
            AppointmentDetailsItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return AppointmentDetails(
      id: _toInt(json['id']),
      reference: json['reference']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      customer: customer,
      department: department,
      requestedStartAt: _toDateTime(json['requested_start_at']),
      confirmedStartAt: _toDateTime(json['confirmed_start_at']),
      customerNotes: _toNullableText(json['customer_notes']),
      adminNotes: _toNullableText(json['admin_notes']),
      cancelledBy: _toNullableText(json['cancelled_by']),
      cancellationReason: _toNullableText(json['cancellation_reason']),
      cancelledAt: _toDateTime(json['cancelled_at']),
      completedAt: _toDateTime(json['completed_at']),
      noShowAt: _toDateTime(json['no_show_at']),
      items: items,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _toDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }

  static String? _toNullableText(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}

class AppointmentCustomer {
  const AppointmentCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isActive,
  });

  const AppointmentCustomer.empty()
    : id = 0,
      name = 'عميلة',
      phone = null,
      email = null,
      isActive = true;

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final bool isActive;

  factory AppointmentCustomer.fromJson(Map<String, dynamic> json) {
    return AppointmentCustomer(
      id: AppointmentDetails._toInt(json['id']),
      name: json['name']?.toString() ?? 'عميلة',
      phone: AppointmentDetails._toNullableText(json['phone']),
      email: AppointmentDetails._toNullableText(json['email']),
      isActive:
          json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active']?.toString() == '1',
    );
  }
}

class AppointmentDepartment {
  const AppointmentDepartment({
    required this.id,
    required this.code,
    required this.name,
  });

  const AppointmentDepartment.empty() : id = 0, code = '', name = 'غير محدد';

  final int id;
  final String code;
  final String name;

  factory AppointmentDepartment.fromJson(Map<String, dynamic> json) {
    return AppointmentDepartment(
      id: AppointmentDetails._toInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'غير محدد',
    );
  }
}

class AppointmentDetailsItem {
  const AppointmentDetailsItem({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.priceType,
    required this.unitPrice,
    required this.durationMinutes,
    required this.notes,
    required this.services,
  });

  final int id;
  final String name;
  final String type;
  final int quantity;
  final String? priceType;
  final double? unitPrice;
  final int? durationMinutes;
  final String? notes;
  final List<AppointmentExecutableService> services;

  factory AppointmentDetailsItem.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    final services = <AppointmentExecutableService>[];

    if (rawServices is List) {
      for (final service in rawServices) {
        if (service is Map) {
          services.add(
            AppointmentExecutableService.fromJson(
              Map<String, dynamic>.from(service),
            ),
          );
        }
      }
    }

    return AppointmentDetailsItem(
      id: AppointmentDetails._toInt(json['id']),
      name: json['item_name']?.toString() ?? json['name']?.toString() ?? 'خدمة',
      type:
          json['item_type']?.toString() ??
          json['type']?.toString() ??
          'service',
      quantity: AppointmentDetails._toInt(json['quantity']).clamp(1, 999),
      priceType: AppointmentDetails._toNullableText(json['price_type']),
      unitPrice: AppointmentDetails._toDouble(
        json['unit_price'] ?? json['price'],
      ),
      durationMinutes: json['duration_minutes'] == null
          ? null
          : AppointmentDetails._toInt(json['duration_minutes']),
      notes: AppointmentDetails._toNullableText(json['notes']),
      services: services,
    );
  }
}

class AppointmentExecutableService {
  const AppointmentExecutableService({
    required this.id,
    required this.name,
    required this.quantity,
    required this.durationMinutes,
    required this.unitPrice,
  });

  final int id;
  final String name;
  final int quantity;
  final int? durationMinutes;
  final double? unitPrice;

  factory AppointmentExecutableService.fromJson(Map<String, dynamic> json) {
    return AppointmentExecutableService(
      id: AppointmentDetails._toInt(json['id']),
      name:
          json['service_name']?.toString() ??
          json['name']?.toString() ??
          'خدمة',
      quantity: AppointmentDetails._toInt(json['quantity']).clamp(1, 999),
      durationMinutes: json['duration_minutes'] == null
          ? null
          : AppointmentDetails._toInt(json['duration_minutes']),
      unitPrice: AppointmentDetails._toDouble(
        json['unit_price'] ?? json['price'],
      ),
    );
  }
}
