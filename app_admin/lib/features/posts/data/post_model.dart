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
  final String imageUrl;
  final bool isActive;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: _parseInt(json['id']),
      department: json['department']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      isActive: _parseBool(json['is_active']),
      description: json['description']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;

    if (value is num) {
      return value != 0;
    }

    final String normalized = value?.toString().toLowerCase() ?? '';

    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static DateTime? _parseDate(Object? value) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
