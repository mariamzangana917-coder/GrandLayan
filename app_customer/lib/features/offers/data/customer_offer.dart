import '../../../core/network/api_url.dart';

class CustomerOffer {
  const CustomerOffer({
    required this.id,
    required this.department,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.availability,
    this.catalogItem,
    this.description,
    this.badgeText,
    this.valueText,
    this.detailsText,
    this.imageUrl,
  });

  final int id;
  final CustomerOfferDepartment department;
  final CustomerOfferCatalogItem? catalogItem;
  final String title;
  final String? description;
  final String? badgeText;
  final String? valueText;
  final String? detailsText;
  final String? imageUrl;
  final DateTime startsAt;
  final DateTime endsAt;
  final String availability;

  factory CustomerOffer.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> department = _requiredMap(
      json['department'],
      field: 'department',
    );
    final Map<String, dynamic>? catalogItem = _nullableMap(
      json['catalog_item'],
    );
    final String? rawImageUrl = _nullableString(json['image_url']);

    return CustomerOffer(
      id: _requiredInt(json['id'], field: 'id'),
      department: CustomerOfferDepartment.fromJson(department),
      catalogItem: catalogItem == null
          ? null
          : CustomerOfferCatalogItem.fromJson(catalogItem),
      title: _requiredString(json['title'], field: 'title'),
      description: _nullableString(json['description']),
      badgeText: _nullableString(json['badge_text']),
      valueText: _nullableString(json['value_text']),
      detailsText: _nullableString(json['details_text']),
      imageUrl: rawImageUrl == null
          ? null
          : ApiUrl.resolveStorageUrl(rawImageUrl),
      startsAt: _requiredDate(json['starts_at'], field: 'starts_at'),
      endsAt: _requiredDate(json['ends_at'], field: 'ends_at'),
      availability: _nullableString(json['availability']) ?? 'current',
    );
  }
}

class CustomerOfferDepartment {
  const CustomerOfferDepartment({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  factory CustomerOfferDepartment.fromJson(Map<String, dynamic> json) {
    return CustomerOfferDepartment(
      id: _requiredInt(json['id'], field: 'department.id'),
      code: _requiredString(json['code'], field: 'department.code'),
      name: _requiredString(json['name'], field: 'department.name'),
    );
  }
}

class CustomerOfferCatalogItem {
  const CustomerOfferCatalogItem({
    required this.id,
    required this.name,
    required this.type,
    required this.priceType,
    required this.isActive,
    this.price,
    this.durationMinutes,
  });

  final int id;
  final String name;
  final String type;
  final String priceType;
  final String? price;
  final int? durationMinutes;
  final bool isActive;

  factory CustomerOfferCatalogItem.fromJson(Map<String, dynamic> json) {
    return CustomerOfferCatalogItem(
      id: _requiredInt(json['id'], field: 'catalog_item.id'),
      name: _requiredString(json['name'], field: 'catalog_item.name'),
      type: _requiredString(json['type'], field: 'catalog_item.type'),
      priceType: _requiredString(
        json['price_type'],
        field: 'catalog_item.price_type',
      ),
      price: _nullableString(json['price']),
      durationMinutes: _nullableInt(json['duration_minutes']),
      isActive: _boolValue(json['is_active'], defaultValue: true),
    );
  }
}

Map<String, dynamic> _requiredMap(dynamic value, {required String field}) {
  final Map<String, dynamic>? map = _nullableMap(value);
  if (map == null) {
    throw FormatException('الحقل $field غير صالح.');
  }
  return map;
}

Map<String, dynamic>? _nullableMap(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic item) => MapEntry(key.toString(), item),
    );
  }
  return null;
}

int _requiredInt(dynamic value, {required String field}) {
  final int? result = _nullableInt(value);
  if (result == null) {
    throw FormatException('الحقل $field غير صالح.');
  }
  return result;
}

int? _nullableInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

String _requiredString(dynamic value, {required String field}) {
  final String? result = _nullableString(value);
  if (result == null) {
    throw FormatException('الحقل $field غير صالح.');
  }
  return result;
}

String? _nullableString(dynamic value) {
  final String result = value?.toString().trim() ?? '';
  return result.isEmpty ? null : result;
}

DateTime _requiredDate(dynamic value, {required String field}) {
  final DateTime? result = DateTime.tryParse(value?.toString() ?? '');
  if (result == null) {
    throw FormatException('الحقل $field غير صالح.');
  }
  return result;
}

bool _boolValue(dynamic value, {required bool defaultValue}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final String normalized = value?.toString().trim().toLowerCase() ?? '';
  if (normalized == 'true' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == '0') {
    return false;
  }
  return defaultValue;
}
