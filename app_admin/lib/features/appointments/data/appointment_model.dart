class AppointmentListResponse {
  const AppointmentListResponse({
    required this.appointments,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.departments,
  });

  final List<AdminAppointment> appointments;
  final int currentPage;
  final int lastPage;
  final int total;
  final List<AppointmentDepartmentFilter> departments;

  factory AppointmentListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawMeta = json['meta'];
    final rawFilters = json['filters'];

    final appointments = <AdminAppointment>[];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map) {
          appointments.add(
            AdminAppointment.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    final departments = <AppointmentDepartmentFilter>[];
    if (rawFilters is Map && rawFilters['departments'] is List) {
      for (final item in rawFilters['departments'] as List) {
        if (item is Map) {
          departments.add(
            AppointmentDepartmentFilter.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return AppointmentListResponse(
      appointments: appointments,
      currentPage: _toInt(meta['current_page'], fallback: 1),
      lastPage: _toInt(meta['last_page'], fallback: 1),
      total: _toInt(meta['total'], fallback: appointments.length),
      departments: departments,
    );
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class AppointmentDepartmentFilter {
  const AppointmentDepartmentFilter({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  factory AppointmentDepartmentFilter.fromJson(Map<String, dynamic> json) {
    return AppointmentDepartmentFilter(
      id: AppointmentListResponse._toInt(json['id'], fallback: 0),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class AdminAppointment {
  const AdminAppointment({
    required this.id,
    required this.reference,
    required this.customerName,
    required this.customerPhone,
    required this.departmentName,
    required this.departmentCode,
    required this.status,
    required this.requestedStartAt,
    required this.confirmedStartAt,
    required this.customerNotes,
    required this.itemNames,
  });

  final int id;
  final String reference;
  final String customerName;
  final String? customerPhone;
  final String departmentName;
  final String departmentCode;
  final String status;
  final DateTime? requestedStartAt;
  final DateTime? confirmedStartAt;
  final String? customerNotes;
  final List<String> itemNames;

  factory AdminAppointment.fromJson(Map<String, dynamic> json) {
    final rawCustomer = json['customer'];
    final rawDepartment = json['department'];
    final rawItems = json['items'];

    final customer = rawCustomer is Map
        ? Map<String, dynamic>.from(rawCustomer)
        : <String, dynamic>{};

    final department = rawDepartment is Map
        ? Map<String, dynamic>.from(rawDepartment)
        : <String, dynamic>{};

    final itemNames = <String>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is! Map) {
          continue;
        }

        final mappedItem = Map<String, dynamic>.from(item);
        final name = mappedItem['item_name'] ?? mappedItem['name'];

        if (name != null && name.toString().trim().isNotEmpty) {
          itemNames.add(name.toString());
        }
      }
    }

    return AdminAppointment(
      id: AppointmentListResponse._toInt(json['id'], fallback: 0),
      reference: json['reference']?.toString() ?? '',
      customerName: customer['name']?.toString() ?? 'عميلة',
      customerPhone: customer['phone']?.toString(),
      departmentName: department['name']?.toString() ?? 'غير محدد',
      departmentCode: department['code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      requestedStartAt: DateTime.tryParse(
        json['requested_start_at']?.toString() ?? '',
      ),
      confirmedStartAt: DateTime.tryParse(
        json['confirmed_start_at']?.toString() ?? '',
      ),
      customerNotes: json['customer_notes']?.toString(),
      itemNames: itemNames,
    );
  }

  String get servicesText {
    if (itemNames.isEmpty) {
      return 'لا توجد خدمات';
    }

    return itemNames.join(' + ');
  }
}
