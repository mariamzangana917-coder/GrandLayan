class CatalogResponse {
  const CatalogResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<CatalogItemModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory CatalogResponse.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final data = json['data'];
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};

    final items = <CatalogItemModel>[];

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          items.add(
            CatalogItemModel.fromJson(
              Map<String, dynamic>.from(item),
              apiBaseUrl: apiBaseUrl,
            ),
          );
        }
      }
    }

    return CatalogResponse(
      items: items,
      currentPage: _int(meta['current_page'], 1),
      lastPage: _int(meta['last_page'], 1),
      total: _int(meta['total'], items.length),
    );
  }

  CatalogResponse copyWith({
    List<CatalogItemModel>? items,
    int? currentPage,
    int? lastPage,
    int? total,
  }) {
    return CatalogResponse(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
    );
  }

  static int _int(dynamic value, int fallback) {
    return value is int
        ? value
        : int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class CatalogItemModel {
  const CatalogItemModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.categoryName,
    required this.departmentName,
    required this.departmentCode,
    required this.priceType,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
    required this.mainImageUrl,
  });

  final int id;
  final String name;
  final String type;
  final String? description;
  final String categoryName;
  final String departmentName;
  final String departmentCode;
  final String priceType;
  final double? price;
  final int? durationMinutes;
  final bool isActive;
  final String? mainImageUrl;

  bool get isPackage => type == 'package';

  factory CatalogItemModel.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : <String, dynamic>{};

    final departmentSource = json['department'] ?? category['department'];

    final department = departmentSource is Map
        ? Map<String, dynamic>.from(departmentSource)
        : <String, dynamic>{};

    return CatalogItemModel(
      id: CatalogResponse._int(json['id'], 0),
      name: json['name']?.toString() ?? 'عنصر بدون اسم',
      type: json['type']?.toString() ?? 'service',
      description: _nullableText(json['description']),
      categoryName: category['name']?.toString() ?? 'غير مصنف',
      departmentName: department['name']?.toString() ?? 'غير محدد',
      departmentCode: department['code']?.toString() ?? '',
      priceType: json['price_type']?.toString() ?? 'fixed',
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? ''),
      durationMinutes: json['duration_minutes'] == null
          ? null
          : CatalogResponse._int(json['duration_minutes'], 0),
      isActive: _toBool(json['is_active']),
      mainImageUrl: _extractImageUrl(json, apiBaseUrl),
    );
  }

  static String? _extractImageUrl(
    Map<String, dynamic> json,
    String apiBaseUrl,
  ) {
    dynamic rawUrl =
        json['main_image_url'] ?? json['image_url'] ?? json['main_image'];

    if (rawUrl is Map) {
      rawUrl = rawUrl['url'] ?? rawUrl['image_url'] ?? rawUrl['path'];
    }

    if (rawUrl == null && json['images'] is List) {
      final images = json['images'] as List;
      Map<String, dynamic>? selected;

      for (final item in images) {
        if (item is! Map) {
          continue;
        }

        final image = Map<String, dynamic>.from(item);

        final isMain = _toBool(image['is_main']);

        if (isMain) {
          selected = image;
          break;
        }

        selected ??= image;
      }

      rawUrl = selected?['url'] ?? selected?['image_url'] ?? selected?['path'];
    }

    final text = _nullableText(rawUrl);

    if (text == null) {
      return null;
    }

    return _normalizeMediaUrl(text, apiBaseUrl);
  }

  static String _normalizeMediaUrl(String rawUrl, String apiBaseUrl) {
    final apiUri = Uri.tryParse(apiBaseUrl);
    final rawUri = Uri.tryParse(rawUrl);

    if (rawUri != null && rawUri.hasScheme) {
      if (apiUri != null &&
          (rawUri.host == '127.0.0.1' || rawUri.host == 'localhost')) {
        return rawUri
            .replace(
              scheme: apiUri.scheme,
              host: apiUri.host,
              port: apiUri.hasPort ? apiUri.port : null,
            )
            .toString();
      }

      return rawUrl;
    }

    if (apiUri == null) {
      return rawUrl;
    }

    final origin = apiUri.replace(path: '', query: null, fragment: null);

    final normalizedPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';

    return origin.replace(path: normalizedPath).toString();
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase();

    return text == '1' || text == 'true';
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
