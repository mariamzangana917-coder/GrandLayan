import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum AppointmentStatusCategory {
  all,
  upcoming,
  past,
}

class CustomerAppointmentListResponse {
  const CustomerAppointmentListResponse({
    required this.appointments,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<CustomerAppointment> appointments;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMorePages => currentPage < lastPage;

  factory CustomerAppointmentListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawMeta = json['meta'];

    final appointments = <CustomerAppointment>[];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map) {
          appointments.add(
            CustomerAppointment.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    return CustomerAppointmentListResponse(
      appointments: appointments,
      currentPage: _toInt(meta['current_page'], fallback: 1),
      lastPage: _toInt(meta['last_page'], fallback: 1),
      perPage: _toInt(meta['per_page'], fallback: 15),
      total: _toInt(meta['total'], fallback: appointments.length),
    );
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class CustomerAppointment {
  const CustomerAppointment({
    required this.id,
    required this.reference,
    required this.department,
    required this.status,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.requestedStartAt,
    required this.confirmedStartAt,
    required this.customerNotes,
    required this.cancelledBy,
    required this.cancellationReason,
    required this.cancelledAt,
    required this.items,
    required this.coupon,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String reference;
  final CustomerAppointmentDepartment department;
  final String status;
  final double? subtotalAmount;
  final double discountAmount;
  final double? finalAmount;
  final DateTime? requestedStartAt;
  final DateTime? confirmedStartAt;
  final String? customerNotes;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final List<CustomerAppointmentItem> items;
  final CustomerAppointmentCoupon? coupon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime? get effectiveStartAt => confirmedStartAt ?? requestedStartAt;

  bool get isUpcoming =>
      status == 'pending' || status == 'confirmed' || status == 'in_progress';

  bool get isPast =>
      status == 'completed' || status == 'cancelled' || status == 'no_show';

  bool get canBeCancelled => status == 'pending' || status == 'confirmed';

  String get statusLabel {
    return switch (status) {
      'pending' => 'قيد المراجعة',
      'confirmed' => 'مؤكد',
      'in_progress' => 'جاري التنفيذ',
      'completed' => 'مكتمل',
      'cancelled' => 'ملغي',
      'no_show' => 'لم تحضر الزبونة',
      _ => status,
    };
  }

  String get statusDescription {
    return switch (status) {
      'pending' => 'طلب الحجز قيد المراجعة والاعتماد من قبل الإدارة.',
      'confirmed' => 'تم تأكيد موعدكِ بنجاح، بانتظار تشريفكِ للصالون/العيادة.',
      'in_progress' => 'الخدمات قيد التنفيذ الآن داخل المركز.',
      'completed' => 'تم إكمال موعدكِ بنجاح. نتمنى لكِ تجربة رائعة!',
      'cancelled' => cancelledBy == 'customer'
          ? 'تم إلغاء هذا الموعد بناءً على طلبكِ.'
          : 'تم إلغاء هذا الموعد من قبل الإدارة.',
      'no_show' => 'تم تسجيل عدم الحضور لهذا الموعد.',
      _ => '',
    };
  }

  Color get statusColor {
    return switch (status) {
      'pending' => const Color(0xFFF59E0B), // Amber/Warning
      'confirmed' => const Color(0xFF10B981), // Green/Success
      'in_progress' => const Color(0xFF3B82F6), // Blue/Info
      'completed' => const Color(0xFF8B5CF6), // Purple
      'cancelled' => const Color(0xFFEF4444), // Red/Error
      'no_show' => const Color(0xFF6B7280), // Gray
      _ => AppColors.gold,
    };
  }

  IconData get statusIcon {
    return switch (status) {
      'pending' => Icons.hourglass_top_rounded,
      'confirmed' => Icons.check_circle_outline_rounded,
      'in_progress' => Icons.autorenew_rounded,
      'completed' => Icons.task_alt_rounded,
      'cancelled' => Icons.cancel_outlined,
      'no_show' => Icons.event_busy_rounded,
      _ => Icons.calendar_today_rounded,
    };
  }

  String get summaryServicesText {
    if (items.isEmpty) {
      return 'لا توجد خدمات محددة';
    }
    return items.map((e) => e.itemName).join(' + ');
  }

  int get totalDurationMinutes {
    int total = 0;
    for (final item in items) {
      if (item.durationMinutes != null && item.durationMinutes! > 0) {
        total += item.durationMinutes! * item.quantity;
      }
    }
    return total;
  }

  factory CustomerAppointment.fromJson(Map<String, dynamic> json) {
    final rawDepartment = json['department'];
    final rawCoupon = json['coupon'];
    final rawItems = json['items'];

    final department = rawDepartment is Map
        ? CustomerAppointmentDepartment.fromJson(
            Map<String, dynamic>.from(rawDepartment),
          )
        : const CustomerAppointmentDepartment.empty();

    final coupon = rawCoupon is Map
        ? CustomerAppointmentCoupon.fromJson(
            Map<String, dynamic>.from(rawCoupon),
          )
        : null;

    final items = <CustomerAppointmentItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(
            CustomerAppointmentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return CustomerAppointment(
      id: _toInt(json['id']),
      reference: json['reference']?.toString() ?? '',
      department: department,
      status: json['status']?.toString() ?? 'pending',
      subtotalAmount: _toDouble(json['subtotal_amount']),
      discountAmount: _toDouble(json['discount_amount']) ?? 0.0,
      finalAmount: _toDouble(json['final_amount']),
      requestedStartAt: _toDateTime(json['requested_start_at']),
      confirmedStartAt: _toDateTime(json['confirmed_start_at']),
      customerNotes: _toNullableText(json['customer_notes']),
      cancelledBy: _toNullableText(json['cancelled_by']),
      cancellationReason: _toNullableText(json['cancellation_reason']),
      cancelledAt: _toDateTime(json['cancelled_at']),
      items: items,
      coupon: coupon,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _toNullableText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}

class CustomerAppointmentDepartment {
  const CustomerAppointmentDepartment({
    required this.id,
    required this.code,
    required this.name,
  });

  const CustomerAppointmentDepartment.empty()
      : id = 0,
        code = '',
        name = 'غير محدد';

  final int id;
  final String code;
  final String name;

  bool get isSalon => code == 'salon';
  bool get isClinic => code == 'clinic';

  factory CustomerAppointmentDepartment.fromJson(Map<String, dynamic> json) {
    return CustomerAppointmentDepartment(
      id: CustomerAppointment._toInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'غير محدد',
    );
  }
}

class CustomerAppointmentCoupon {
  const CustomerAppointmentCoupon({
    required this.id,
    required this.name,
    required this.code,
    required this.discountType,
    required this.discountValue,
  });

  final int id;
  final String name;
  final String code;
  final String discountType;
  final double discountValue;

  factory CustomerAppointmentCoupon.fromJson(Map<String, dynamic> json) {
    return CustomerAppointmentCoupon(
      id: CustomerAppointment._toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'fixed',
      discountValue:
          CustomerAppointment._toDouble(json['discount_value']) ?? 0.0,
    );
  }
}

class CustomerAppointmentItem {
  const CustomerAppointmentItem({
    required this.id,
    required this.catalogItemId,
    required this.itemType,
    required this.itemName,
    required this.priceType,
    required this.unitPrice,
    required this.quantity,
    required this.durationMinutes,
    required this.services,
  });

  final int id;
  final int catalogItemId;
  final String itemType;
  final String itemName;
  final String priceType;
  final double? unitPrice;
  final int quantity;
  final int? durationMinutes;
  final List<CustomerAppointmentService> services;

  bool get isPackage => itemType == 'package';
  bool get isService => itemType == 'service';

  factory CustomerAppointmentItem.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    final services = <CustomerAppointmentService>[];

    if (rawServices is List) {
      for (final service in rawServices) {
        if (service is Map) {
          services.add(
            CustomerAppointmentService.fromJson(
              Map<String, dynamic>.from(service),
            ),
          );
        }
      }
    }

    return CustomerAppointmentItem(
      id: CustomerAppointment._toInt(json['id']),
      catalogItemId: CustomerAppointment._toInt(json['catalog_item_id']),
      itemType: json['item_type']?.toString() ?? 'service',
      itemName: json['item_name']?.toString() ?? 'خدمة',
      priceType: json['price_type']?.toString() ?? 'fixed',
      unitPrice: CustomerAppointment._toDouble(json['unit_price']),
      quantity: CustomerAppointment._toInt(json['quantity']).clamp(1, 999),
      durationMinutes: json['duration_minutes'] == null
          ? null
          : CustomerAppointment._toInt(json['duration_minutes']),
      services: services,
    );
  }
}

class CustomerAppointmentService {
  const CustomerAppointmentService({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.durationMinutes,
    required this.unitPrice,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.notes,
  });

  final int id;
  final int serviceId;
  final String serviceName;
  final int quantity;
  final int durationMinutes;
  final double? unitPrice;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final String? notes;

  factory CustomerAppointmentService.fromJson(Map<String, dynamic> json) {
    return CustomerAppointmentService(
      id: CustomerAppointment._toInt(json['id']),
      serviceId: CustomerAppointment._toInt(json['service_id']),
      serviceName: json['service_name']?.toString() ?? 'خدمة',
      quantity: CustomerAppointment._toInt(json['quantity']).clamp(1, 999),
      durationMinutes:
          CustomerAppointment._toInt(json['duration_minutes']).clamp(0, 9999),
      unitPrice: CustomerAppointment._toDouble(json['unit_price']),
      scheduledStartAt:
          CustomerAppointment._toDateTime(json['scheduled_start_at']),
      scheduledEndAt:
          CustomerAppointment._toDateTime(json['scheduled_end_at']),
      notes: CustomerAppointment._toNullableText(json['notes']),
    );
  }
}
