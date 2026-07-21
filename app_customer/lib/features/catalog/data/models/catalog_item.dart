import 'catalog_category.dart';
import 'catalog_image.dart';
import 'department.dart';

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.type,
    required this.priceType,
    required this.isActive,
    required this.isFavorite,
    this.description,
    this.instructions,
    this.price,
    this.durationMinutes,
    this.department,
    this.category,
    this.images = const <CatalogImage>[],
  });

  final int id;
  final String name;
  final String type;
  final String priceType;
  final bool isActive;
  final bool isFavorite;
  final String? description;
  final String? instructions;
  final double? price;
  final int? durationMinutes;
  final Department? department;
  final CatalogCategory? category;
  final List<CatalogImage> images;

  bool get isService => type == 'service';

  bool get isPackage => type == 'package';

  bool get hasFixedPrice => priceType == 'fixed' && price != null;

  String get displayPrice {
    if (priceType == 'inspection') {
      return 'السعر بعد المعاينة';
    }

    if (price == null) {
      return 'السعر غير محدد';
    }

    final double currentPrice = price!;

    if (currentPrice == currentPrice.roundToDouble()) {
      return '${currentPrice.toInt()} د.ع';
    }

    return '${currentPrice.toStringAsFixed(2)} د.ع';
  }

  String? get primaryImageUrl {
    for (final CatalogImage image in images) {
      if (image.isPrimary && image.url?.trim().isNotEmpty == true) {
        return image.url!.trim();
      }
    }

    for (final CatalogImage image in images) {
      if (image.url?.trim().isNotEmpty == true) {
        return image.url!.trim();
      }
    }

    return null;
  }

  CatalogItem copyWith({
    int? id,
    String? name,
    String? type,
    String? priceType,
    bool? isActive,
    bool? isFavorite,
    String? description,
    String? instructions,
    double? price,
    int? durationMinutes,
    Department? department,
    CatalogCategory? category,
    List<CatalogImage>? images,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      priceType: priceType ?? this.priceType,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      department: department ?? this.department,
      category: category ?? this.category,
      images: images ?? this.images,
    );
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final dynamic departmentData = json['department'];
    final dynamic categoryData = json['category'];
    final dynamic imagesData = json['images'];

    return CatalogItem(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'service',
      priceType: json['price_type']?.toString() ?? 'fixed',
      isActive: _toBool(json['is_active'], defaultValue: true),
      isFavorite: _toBool(json['is_favorite'], defaultValue: false),
      description: _toNullableString(json['description']),
      instructions: _toNullableString(json['instructions']),
      price: _toNullableDouble(json['price']),
      durationMinutes: _toNullableInt(json['duration_minutes']),
      department: departmentData is Map
          ? Department.fromJson(
              departmentData.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ),
            )
          : null,
      category: categoryData is Map
          ? CatalogCategory.fromJson(
              categoryData.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ),
            )
          : null,
      images: imagesData is List
          ? imagesData
                .whereType<Map>()
                .map(
                  (Map<dynamic, dynamic> image) => CatalogImage.fromJson(
                    image.map(
                      (dynamic key, dynamic value) =>
                          MapEntry(key.toString(), value),
                    ),
                  ),
                )
                .toList(growable: false)
          : const <CatalogImage>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type,
      'price_type': priceType,
      'is_active': isActive,
      'is_favorite': isFavorite,
      'description': description,
      'instructions': instructions,
      'price': price,
      'duration_minutes': durationMinutes,
      'department': department?.toJson(),
      'category': category?.toJson(),
      'images': images
          .map((CatalogImage image) => image.toJson())
          .toList(growable: false),
    };
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

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static String? _toNullableString(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static bool _toBool(dynamic value, {required bool defaultValue}) {
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
