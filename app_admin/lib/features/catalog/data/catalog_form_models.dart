class CatalogCategoryOption {
  const CatalogCategoryOption({
    required this.id,
    required this.name,
    required this.departmentCode,
  });

  final int id;
  final String name;
  final String departmentCode;

  factory CatalogCategoryOption.fromJson(Map<String, dynamic> json) {
    final department = json['department'] is Map
        ? Map<String, dynamic>.from(json['department'] as Map)
        : <String, dynamic>{};

    return CatalogCategoryOption(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'تصنيف',
      departmentCode: department['code']?.toString() ?? '',
    );
  }
}

class CatalogServiceOption {
  const CatalogServiceOption({
    required this.id,
    required this.name,
    required this.durationMinutes,
  });

  final int id;
  final String name;
  final int? durationMinutes;

  factory CatalogServiceOption.fromJson(Map<String, dynamic> json) {
    return CatalogServiceOption(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'خدمة',
      durationMinutes: json['duration_minutes'] == null
          ? null
          : _toInt(json['duration_minutes']),
    );
  }
}

class PackageServiceDraft {
  const PackageServiceDraft({
    required this.service,
    required this.quantity,
    this.notes,
  });

  final CatalogServiceOption service;
  final int quantity;
  final String? notes;

  PackageServiceDraft copyWith({int? quantity, String? notes}) {
    return PackageServiceDraft(
      service: service,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
