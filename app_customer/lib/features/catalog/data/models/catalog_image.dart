import '../../../../core/network/api_url.dart';

class CatalogImage {
  const CatalogImage({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
    required this.sortOrder,
  });

  final int id;
  final String? imageUrl;
  final bool isPrimary;
  final int sortOrder;

  // للتوافق مع catalog_item.dart القديم
  String? get url => imageUrl;

  factory CatalogImage.fromJson(Map<String, dynamic> json) {
    return CatalogImage(
      id: (json['id'] as num).toInt(),
      imageUrl: ApiUrl.resolveStorageUrl(_readImageUrl(json)),
      isPrimary: _readBool(json['is_primary']),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'image_url': imageUrl,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
    };
  }

  static String? _readImageUrl(Map<String, dynamic> json) {
    final Object? value =
        json['image_url'] ?? json['url'] ?? json['full_url'] ?? json['path'];

    if (value == null) {
      return null;
    }

    final String result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized = value?.toString().toLowerCase() ?? '';

    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}
