import 'catalog_category.dart';
import 'catalog_image.dart';

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.type,
    required this.priceType,
    required this.isActive,
    required this.isFavorite,
    required this.images,
    this.categoryId,
    this.description,
    this.instructions,
    this.price,
    this.durationMinutes,
    this.category,
  });

  final int id;
  final int? categoryId;
  final String name;
  final String type;
  final String? description;
  final String? instructions;
  final String priceType;
  final double? price;
  final int? durationMinutes;
  final bool isActive;
  final bool isFavorite;
  final CatalogCategory? category;
  final List<CatalogImage> images;

  bool get isService => type == 'service';

  bool get isPackage => type == 'package';

  bool get requiresInspection => priceType == 'inspection';

  CatalogImage? get mainImage {
    if (images.isEmpty) {
      return null;
    }

    for (final CatalogImage image in images) {
      if (image.isMain) {
        return image;
      }
    }

    final List<CatalogImage> sortedImages =
        List<CatalogImage>.from(images)
          ..sort(
            (CatalogImage first, CatalogImage second) =>
                first.sortOrder.compareTo(second.sortOrder),
          );

    return sortedImages.first;
  }

  String? get mainImageUrl => mainImage?.url;

  String get displayPrice {
    if (requiresInspection || price == null) {
      return 'يتحدد السعر بعد المعاينة';
    }

    final double currentPrice = price!;

    if (currentPrice == currentPrice.roundToDouble()) {
      return '${currentPrice.toInt()} د.ع';
    }

    return '${currentPrice.toStringAsFixed(2)} د.ع';
  }

  CatalogItem copyWith({
    bool? isFavorite,
  }) {
    return CatalogItem(
      id: id,
      categoryId: categoryId,
      name: name,
      type: type,
      description: description,
      instructions: instructions,
      priceType: priceType,
      price: price,
      durationMinutes: durationMinutes,
      isActive: isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category,
      images: images,
    );
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final dynamic categoryJson = json['category'];
    final dynamic imagesJson = json['images'];

    return CatalogItem(
      id: _toInt(json['id']),
      categoryId: _toNullableInt(json['category_id']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'service',
      description: _nullableText(json['description']),
      instructions: _nullableText(json['instructions']),
      priceType: json['price_type']?.toString() ?? 'fixed',
      price: _toNullableDouble(json['price']),
      durationMinutes: _toNullableInt(json['duration_minutes']),
      isActive: _toBool(json['is_active'], fallback: true),
      isFavorite: _toBool(json['is_favorite']),
      category:
          categoryJson is Map<String, dynamic>
              ? CatalogCategory.fromJson(categoryJson)
              : categoryJson is Map
              ? CatalogCategory.fromJson(
                categoryJson.map(
                  (dynamic key, dynamic value) =>
                      MapEntry(key.toString(), value),
                ),
              )
              : null,
      images:
          imagesJson is List
              ? imagesJson
                  .whereType<Map>()
                  .map(
                    (Map<dynamic, dynamic> image) =>
                        CatalogImage.fromJson(
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

  static String? _nullableText(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
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

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
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