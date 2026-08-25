class AdminCoupon {
  const AdminCoupon({
    required this.id,
    required this.name,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minimumOrderAmount,
    required this.maximumDiscountAmount,
    required this.departmentId,
    required this.department,
    required this.maximumTotalUses,
    required this.maximumUsesPerCustomer,
    required this.usedCount,
    required this.remainingUses,
    required this.startsAt,
    required this.expiresAt,
    required this.isActive,
    required this.isAvailable,
    required this.notes,
    required this.catalogItemIds,
  });

  final int id;
  final String name;
  final String code;
  final String discountType;
  final double discountValue;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final int? departmentId;
  final CouponDepartment? department;
  final int? maximumTotalUses;
  final int maximumUsesPerCustomer;
  final int usedCount;
  final int? remainingUses;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final bool isActive;
  final bool isAvailable;
  final String? notes;
  final List<int> catalogItemIds;

  bool get isPercentage => discountType == 'percentage';

  CouponAvailability get availability {
    if (!isActive) {
      return CouponAvailability.inactive;
    }

    if (maximumTotalUses != null && usedCount >= maximumTotalUses!) {
      return CouponAvailability.exhausted;
    }

    final DateTime now = DateTime.now();

    if (startsAt != null && startsAt!.isAfter(now)) {
      return CouponAvailability.upcoming;
    }

    if (expiresAt != null && !expiresAt!.isAfter(now)) {
      return CouponAvailability.expired;
    }

    return CouponAvailability.available;
  }

  Map<String, dynamic> toPayload({bool? isActiveOverride}) {
    return <String, dynamic>{
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'discount_type': discountType,
      'discount_value': discountValue,
      'minimum_order_amount': minimumOrderAmount,
      'maximum_discount_amount': isPercentage ? maximumDiscountAmount : null,
      'department_id': departmentId,
      'maximum_total_uses': maximumTotalUses,
      'maximum_uses_per_customer': maximumUsesPerCustomer,
      'starts_at': startsAt?.toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'is_active': isActiveOverride ?? isActive,
      'notes': notes,
      'catalog_item_ids': catalogItemIds,
    };
  }

  factory AdminCoupon.fromJson(Map<String, dynamic> json) {
    final dynamic rawDepartment = json['department'];
    final dynamic rawCatalogItemIds = json['catalog_item_ids'];

    final List<int> catalogItemIds = <int>[];

    if (rawCatalogItemIds is List) {
      for (final dynamic value in rawCatalogItemIds) {
        final int id = _toInt(value);

        if (id > 0 && !catalogItemIds.contains(id)) {
          catalogItemIds.add(id);
        }
      }
    }

    return AdminCoupon(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'percentage',
      discountValue: _toDouble(json['discount_value']),
      minimumOrderAmount: _toNullableDouble(json['minimum_order_amount']),
      maximumDiscountAmount: _toNullableDouble(json['maximum_discount_amount']),
      departmentId: _toNullableInt(json['department_id']),
      department: rawDepartment is Map
          ? CouponDepartment.fromJson(Map<String, dynamic>.from(rawDepartment))
          : null,
      maximumTotalUses: _toNullableInt(json['maximum_total_uses']),
      maximumUsesPerCustomer: _toInt(json['maximum_uses_per_customer']) < 1
          ? 1
          : _toInt(json['maximum_uses_per_customer']),
      usedCount: _toInt(json['used_count']),
      remainingUses: _toNullableInt(json['remaining_uses']),
      startsAt: _toNullableDateTime(json['starts_at']),
      expiresAt: _toNullableDateTime(json['expires_at']),
      isActive: _toBool(json['is_active']),
      isAvailable: _toBool(json['is_available']),
      notes: _toNullableString(json['notes']),
      catalogItemIds: List<int>.unmodifiable(catalogItemIds),
    );
  }

  static String? _toNullableString(dynamic value) {
    final String normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return _toInt(value);
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return _toDouble(value);
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

class CouponDepartment {
  const CouponDepartment({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  factory CouponDepartment.fromJson(Map<String, dynamic> json) {
    final String normalizedCode = json['code']?.toString().trim() ?? '';

    return CouponDepartment(
      id: AdminCoupon._toInt(json['id']),
      name: (json['name'] ?? json['name_ar'] ?? '').toString(),
      code: normalizedCode.isEmpty ? null : normalizedCode,
    );
  }
}

class CouponCatalogItem {
  const CouponCatalogItem({
    required this.id,
    required this.name,
    required this.type,
  });

  final int id;
  final String name;
  final String type;

  factory CouponCatalogItem.fromJson(Map<String, dynamic> json) {
    return CouponCatalogItem(
      id: AdminCoupon._toInt(json['id']),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      type: json['type']?.toString() ?? 'service',
    );
  }
}

enum CouponAvailability { available, upcoming, expired, exhausted, inactive }

class AdminCouponPage {
  const AdminCouponPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminCoupon> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AdminCouponPage.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['data'];
    final dynamic rawMeta = json['meta'];
    final List<AdminCoupon> items = <AdminCoupon>[];

    if (rawItems is List) {
      for (final dynamic rawItem in rawItems) {
        if (rawItem is Map) {
          items.add(AdminCoupon.fromJson(Map<String, dynamic>.from(rawItem)));
        }
      }
    }

    final Map<String, dynamic> meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    final int currentPage = AdminCoupon._toInt(meta['current_page']);
    final int lastPage = AdminCoupon._toInt(meta['last_page']);

    return AdminCouponPage(
      items: List<AdminCoupon>.unmodifiable(items),
      currentPage: currentPage < 1 ? 1 : currentPage,
      lastPage: lastPage < 1 ? 1 : lastPage,
      total: AdminCoupon._toInt(meta['total']),
    );
  }
}

class CouponDeleteResult {
  const CouponDeleteResult({
    required this.message,
    required this.deleted,
    required this.deactivated,
  });

  final String message;
  final bool deleted;
  final bool deactivated;

  factory CouponDeleteResult.fromJson(Map<String, dynamic> json) {
    return CouponDeleteResult(
      message: json['message']?.toString() ?? 'تم تحديث الكوبون.',
      deleted: AdminCoupon._toBool(json['deleted']),
      deactivated: AdminCoupon._toBool(json['deactivated']),
    );
  }
}
