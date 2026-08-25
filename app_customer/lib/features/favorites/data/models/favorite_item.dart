import '../../../catalog/data/models/catalog_item.dart';

class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.catalogItem,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final CatalogItem catalogItem;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final dynamic catalogItemData = json['catalog_item'];

    return FavoriteItem(
      id: _toInt(json['id']),
      catalogItem: catalogItemData is Map
          ? CatalogItem.fromJson(
              catalogItemData.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ),
            )
          : const CatalogItem(
              id: 0,
              name: '',
              type: 'service',
              priceType: 'fixed',
              isActive: false,
              isFavorite: false,
            ),
      createdAt: _toNullableDateTime(json['created_at']),
      updatedAt: _toNullableDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'catalog_item': catalogItem.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toNullableDateTime(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
