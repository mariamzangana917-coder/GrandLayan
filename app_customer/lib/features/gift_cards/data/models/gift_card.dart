class GiftCard {
  const GiftCard({
    required this.id,
    required this.name,
    required this.amount,
    required this.validityDays,
    required this.isActive,
    required this.sortOrder,
    required this.ordersCount,
    this.description,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final String? imagePath;
  final int amount;
  final int validityDays;
  final bool isActive;
  final int sortOrder;
  final int ordersCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GiftCard.fromJson(Map<String, dynamic> json) {
    return GiftCard(
      id: _toInt(json['id']),
      name: json['name']?.toString().trim() ?? '',
      description: _nullableString(json['description']),
      imagePath: _nullableString(json['image_path']),
      amount: _toInt(json['amount']),
      validityDays: _toInt(json['validity_days']),
      isActive: _toBool(json['is_active']),
      sortOrder: _toInt(json['sort_order']),
      ordersCount: _toInt(json['orders_count']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  GiftCard copyWith({
    int? id,
    String? name,
    String? description,
    bool clearDescription = false,
    String? imagePath,
    bool clearImagePath = false,
    int? amount,
    int? validityDays,
    bool? isActive,
    int? sortOrder,
    int? ordersCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GiftCard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : description ?? this.description,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
      amount: amount ?? this.amount,
      validityDays: validityDays ?? this.validityDays,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      ordersCount: ordersCount ?? this.ordersCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

    final normalized = value?.toString().trim().toLowerCase();

    return normalized == 'true' || normalized == '1';
  }

  static String? _nullableString(dynamic value) {
    final result = value?.toString().trim();

    if (result == null || result.isEmpty) {
      return null;
    }

    return result;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
