class PostModel {
  const PostModel({
    required this.id,
    required this.department,
    required this.imageUrl,
    required this.isActive,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String department;
  final String? imageUrl;
  final bool isActive;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: _parseInt(json['id']),
      department: json['department']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      isActive: _parseBool(json['is_active']),
      description: _parseDescription(json['description']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static String? _parseDescription(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized = value?.toString().toLowerCase() ?? '';

    return normalized == 'true' || normalized == '1';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
