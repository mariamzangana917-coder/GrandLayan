import '../../../../core/network/api_config.dart';

class CatalogImage {
  const CatalogImage({
    required this.id,
    required this.url,
    required this.isMain,
    required this.sortOrder,
  });

  final int id;
  final String url;
  final bool isMain;
  final int sortOrder;

  factory CatalogImage.fromJson(Map<String, dynamic> json) {
    final String rawUrl =
        json['url']?.toString() ??
        json['image_url']?.toString() ??
        json['path']?.toString() ??
        '';

    return CatalogImage(
      id: _toInt(json['id']),
      url: _normalizeImageUrl(rawUrl),
      isMain: _toBool(json['is_main']),
      sortOrder: _toInt(json['sort_order'] ?? json['order']),
    );
  }

  static String _normalizeImageUrl(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final Uri apiUri = Uri.parse(ApiConfig.baseUrl);
    final String origin =
        '${apiUri.scheme}://${apiUri.host}'
        '${apiUri.hasPort ? ':${apiUri.port}' : ''}';

    if (trimmed.startsWith('/')) {
      return '$origin$trimmed';
    }

    return '$origin/$trimmed';
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
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

    final String normalized = value?.toString().toLowerCase() ?? '';

    return normalized == 'true' || normalized == '1';
  }
}
