class AdminOffer {
  const AdminOffer({
    required this.id,
    required this.department,
    required this.catalogItem,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.valueText,
    required this.detailsText,
    required this.imageUrl,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
    required this.sortOrder,
    required this.availability,
  });

  final int id;
  final OfferDepartment department;
  final OfferCatalogItem? catalogItem;
  final String title;
  final String? description;
  final String? badgeText;
  final String? valueText;
  final String? detailsText;
  final String? imageUrl;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final int sortOrder;
  final String availability;

  factory AdminOffer.fromJson(Map<String, dynamic> json) {
    final dynamic rawDepartment = json['department'];
    final dynamic rawCatalogItem = json['catalog_item'];

    final Map<String, dynamic> departmentJson = rawDepartment is Map
        ? Map<String, dynamic>.from(rawDepartment)
        : <String, dynamic>{};

    return AdminOffer(
      id: _toInt(json['id']),
      department: OfferDepartment.fromJson(departmentJson),
      catalogItem: rawCatalogItem is Map
          ? OfferCatalogItem.fromJson(Map<String, dynamic>.from(rawCatalogItem))
          : null,
      title: json['title']?.toString() ?? '',
      description: _toNullableString(json['description']),
      badgeText: _toNullableString(json['badge_text']),
      valueText: _toNullableString(json['value_text']),
      detailsText: _toNullableString(json['details_text']),
      imageUrl: _toNullableString(json['image_url']),
      startsAt: _toDateTime(json['starts_at']),
      endsAt: _toDateTime(json['ends_at']),
      isActive: _toBool(json['is_active']),
      sortOrder: _toInt(json['sort_order']),
      availability: json['availability']?.toString() ?? 'inactive',
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

  static DateTime _toDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class OfferDepartment {
  const OfferDepartment({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  factory OfferDepartment.fromJson(Map<String, dynamic> json) {
    return OfferDepartment(
      id: AdminOffer._toInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: (json['name'] ?? json['name_ar'] ?? '').toString(),
    );
  }
}

class OfferCatalogItem {
  const OfferCatalogItem({
    required this.id,
    required this.name,
    required this.type,
    required this.priceType,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
  });

  final int id;
  final String name;
  final String type;
  final String priceType;
  final String? price;
  final int? durationMinutes;
  final bool isActive;

  factory OfferCatalogItem.fromJson(Map<String, dynamic> json) {
    final dynamic rawDuration = json['duration_minutes'];

    return OfferCatalogItem(
      id: AdminOffer._toInt(json['id']),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      type: json['type']?.toString() ?? 'service',
      priceType: json['price_type']?.toString() ?? 'fixed',
      price: AdminOffer._toNullableString(json['price']),
      durationMinutes: rawDuration == null
          ? null
          : AdminOffer._toInt(rawDuration),
      isActive: AdminOffer._toBool(json['is_active']),
    );
  }
}

class AdminOfferPage {
  const AdminOfferPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminOffer> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AdminOfferPage.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['data'];
    final dynamic rawMeta = json['meta'];

    final List<AdminOffer> items = <AdminOffer>[];

    if (rawItems is List) {
      for (final dynamic rawItem in rawItems) {
        if (rawItem is Map) {
          items.add(AdminOffer.fromJson(Map<String, dynamic>.from(rawItem)));
        }
      }
    }

    final Map<String, dynamic> meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    final int parsedCurrentPage = AdminOffer._toInt(meta['current_page']);
    final int parsedLastPage = AdminOffer._toInt(meta['last_page']);

    return AdminOfferPage(
      items: items,
      currentPage: parsedCurrentPage < 1 ? 1 : parsedCurrentPage,
      lastPage: parsedLastPage < 1 ? 1 : parsedLastPage,
      total: AdminOffer._toInt(meta['total']),
    );
  }
}
