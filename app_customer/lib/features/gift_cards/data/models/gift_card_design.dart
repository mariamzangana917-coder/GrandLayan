class GiftCardDesign {
  const GiftCardDesign({
    required this.id,
    required this.name,
    required this.amount,
    required this.isActive,
    required this.sortOrder,
    this.description,
    this.imagePath,
    this.validityDays,
  });

  final int id;
  final String name;
  final String? description;
  final String? imagePath;
  final double amount;
  final int? validityDays;
  final bool isActive;
  final int sortOrder;

  String? get imageUrl {
    final path = imagePath?.trim();

    if (path == null || path.isEmpty) {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/storage/')) {
      return 'http://64.227.16.105$path';
    }

    if (path.startsWith('storage/')) {
      return 'http://64.227.16.105/$path';
    }

    return 'http://64.227.16.105/storage/$path';
  }

  String get formattedAmount {
    final roundedAmount = amount.round();
    final text = roundedAmount.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < text.length; index++) {
      final remaining = text.length - index;

      buffer.write(text[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${buffer.toString()} د.ع';
  }

  factory GiftCardDesign.fromJson(Map<String, dynamic> json) {
    return GiftCardDesign(
      id: _parseInt(json['id']),
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'بطاقة هدية',
      description: _nullableString(json['description']),
      imagePath: _nullableString(json['image_url'] ?? json['image_path']),
      amount: _parseDouble(json['amount']),
      validityDays: _parseNullableInt(json['validity_days']),
      isActive: _parseBool(json['is_active'], fallback: true),
      sortOrder: _parseInt(json['sort_order']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty || text == 'null') {
      return null;
    }

    return text;
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

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().toLowerCase().trim();

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }

    return fallback;
  }
}
