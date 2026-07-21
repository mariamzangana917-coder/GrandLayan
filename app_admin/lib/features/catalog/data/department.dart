class Department {
  const Department({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
  });

  final int id;
  final String name;
  final String code;
  final bool isActive;

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      isActive: _toBool(json['is_active'], fallback: true),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
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