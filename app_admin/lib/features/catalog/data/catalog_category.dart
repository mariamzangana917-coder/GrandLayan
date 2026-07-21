import 'department.dart';

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.isActive,
    this.departmentId,
    this.department,
  });

  final int id;
  final String name;
  final int? departmentId;
  final bool isActive;
  final Department? department;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    final dynamic departmentJson = json['department'];

    return CatalogCategory(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      departmentId: _toNullableInt(json['department_id']),
      isActive: _toBool(json['is_active'], fallback: true),
      department:
          departmentJson is Map<String, dynamic>
              ? Department.fromJson(departmentJson)
              : departmentJson is Map
              ? Department.fromJson(
                departmentJson.map(
                  (dynamic key, dynamic value) =>
                      MapEntry(key.toString(), value),
                ),
              )
              : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized = value?.toString().toLowerCase() ?? '';

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }

    return fallback;
  }
}