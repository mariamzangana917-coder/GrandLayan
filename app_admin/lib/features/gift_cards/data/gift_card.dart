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
      id: _readInt(json['id']),
      name: _readString(json['name']),
      description: _readNullableString(json['description']),
      imagePath: _readNullableString(json['image_path']),
      amount: _readInt(json['amount']),
      validityDays: _readInt(json['validity_days']),
      isActive: _readBool(json['is_active']),
      sortOrder: _readInt(json['sort_order']),
      ordersCount: _readInt(json['orders_count']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
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

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();

    return text == 'true' || text == '1';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
