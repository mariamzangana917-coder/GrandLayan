class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.departmentId,
    required this.departmentCode,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isActive,
    required this.catalogItemsCount,
  });

  final int id;
  final int departmentId;
  final String departmentCode;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int catalogItemsCount;

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    final department = json['department'] is Map
        ? Map<String, dynamic>.from(json['department'] as Map)
        : <String, dynamic>{};

    return AdminCategory(
      id: _int(json['id']),
      departmentId: _int(json['department_id'] ?? department['id']),
      departmentCode: department['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'تصنيف',
      description: _text(json['description']),
      imageUrl: _text(json['image_url']),
      isActive: _bool(json['is_active']),
      catalogItemsCount: _int(json['catalog_items_count']),
    );
  }

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static bool _bool(dynamic value) =>
      value == true || value == 1 || value?.toString() == '1';

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
