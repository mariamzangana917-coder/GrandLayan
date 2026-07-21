import 'department.dart';

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.department,
  });

  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final Department? department;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    final dynamic departmentData = json['department'];

    return CatalogCategory(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: _toNullableString(json['description']),
      isActive: _toBool(json['is_active'], defaultValue: true),
      department: departmentData is Map
          ? Department.fromJson(
              departmentData.map(
                (dynamic key, dynamic value) =>
                    MapEntry(key.toString(), value),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'department': department?.toJson(),
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _toNullableString(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static bool _toBool(
    dynamic value, {
    required bool defaultValue,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().toLowerCase() ?? '';

    if (text == 'true' || text == '1') {
      return true;
    }

    if (text == 'false' || text == '0') {
      return false;
    }

    return defaultValue;
  }
}