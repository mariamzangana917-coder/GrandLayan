class CatalogPage {
  const CatalogPage({required this.items, required this.total});

  final List<CatalogItem> items;
  final int total;

  factory CatalogPage.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final data = json['data'];
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};

    final items = <CatalogItem>[];

    if (data is List) {
      for (final raw in data) {
        if (raw is Map) {
          items.add(
            CatalogItem.fromJson(
              Map<String, dynamic>.from(raw),
              apiBaseUrl: apiBaseUrl,
            ),
          );
        }
      }
    }

    return CatalogPage(
      items: items,
      total: _toInt(meta['total'], items.length),
    );
  }
}

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.instructions,
    required this.priceType,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
    required this.categoryId,
    required this.categoryName,
    required this.departmentId,
    required this.departmentCode,
    required this.departmentName,
    required this.images,
    required this.packageItems,
  });

  final int id;
  final String name;
  final String type;
  final String? description;
  final String? instructions;
  final String priceType;
  final double? price;
  final int? durationMinutes;
  final bool isActive;
  final int categoryId;
  final String categoryName;
  final int departmentId;
  final String departmentCode;
  final String departmentName;
  final List<CatalogImage> images;
  final List<PackageItem> packageItems;

  bool get isPackage => type == 'package';

  CatalogImage? get mainImage {
    for (final image in images) {
      if (image.isMain) return image;
    }
    return images.isEmpty ? null : images.first;
  }

  factory CatalogItem.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : <String, dynamic>{};

    final departmentRaw = json['department'] ?? category['department'];

    final department = departmentRaw is Map
        ? Map<String, dynamic>.from(departmentRaw)
        : <String, dynamic>{};

    final images = <CatalogImage>[];
    final rawImages = json['images'];

    if (rawImages is List) {
      for (final raw in rawImages) {
        if (raw is Map) {
          images.add(
            CatalogImage.fromJson(
              Map<String, dynamic>.from(raw),
              apiBaseUrl: apiBaseUrl,
            ),
          );
        }
      }
    }

    final packageItems = <PackageItem>[];
    final packageRaw =
        json['package_items'] ?? json['items'] ?? json['contents'];

    if (packageRaw is List) {
      for (final raw in packageRaw) {
        if (raw is Map) {
          packageItems.add(
            PackageItem.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
    }

    return CatalogItem(
      id: _toInt(json['id'], 0),
      name: json['name']?.toString() ?? 'عنصر بدون اسم',
      type: json['type']?.toString() ?? 'service',
      description: _nullable(json['description']),
      instructions: _nullable(json['instructions']),
      priceType: json['price_type']?.toString() ?? 'fixed',
      price: _toDouble(json['price']),
      durationMinutes: json['duration_minutes'] == null
          ? null
          : _toInt(json['duration_minutes'], 0),
      isActive: _toBool(json['is_active']),
      categoryId: _toInt(json['category_id'] ?? category['id'], 0),
      categoryName: category['name']?.toString() ?? 'غير مصنف',
      departmentId: _toInt(json['department_id'] ?? department['id'], 0),
      departmentCode: department['code']?.toString() ?? '',
      departmentName: department['name']?.toString() ?? 'غير محدد',
      images: images,
      packageItems: packageItems,
    );
  }
}

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

  factory CatalogImage.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final raw =
        json['url'] ?? json['image_url'] ?? json['path'] ?? json['image_path'];

    return CatalogImage(
      id: _toInt(json['id'], 0),
      url: normalizeMediaUrl(raw?.toString() ?? '', apiBaseUrl),
      isMain: _toBool(json['is_main']),
      sortOrder: _toInt(json['sort_order'] ?? json['ordering'], 0),
    );
  }
}

class PackageItem {
  const PackageItem({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.notes,
  });

  final int id;
  final int serviceId;
  final String serviceName;
  final int quantity;
  final String? notes;

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    final service = json['service'] is Map
        ? Map<String, dynamic>.from(json['service'] as Map)
        : <String, dynamic>{};

    return PackageItem(
      id: _toInt(json['id'], 0),
      serviceId: _toInt(json['service_id'] ?? service['id'], 0),
      serviceName:
          service['name']?.toString() ??
          json['service_name']?.toString() ??
          'خدمة',
      quantity: _toInt(json['quantity'], 1),
      notes: _nullable(json['notes']),
    );
  }
}

class CatalogCategory {
  const CatalogCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: _toInt(json['id'], 0),
      name: json['name']?.toString() ?? 'تصنيف',
    );
  }
}

String normalizeMediaUrl(String rawUrl, String apiBaseUrl) {
  if (rawUrl.isEmpty) return rawUrl;

  final raw = Uri.tryParse(rawUrl);
  final api = Uri.tryParse(apiBaseUrl);

  if (raw != null && raw.hasScheme) {
    if (api != null && (raw.host == '127.0.0.1' || raw.host == 'localhost')) {
      return raw
          .replace(
            scheme: api.scheme,
            host: api.host,
            port: api.hasPort ? api.port : null,
          )
          .toString();
    }

    return rawUrl;
  }

  if (api == null) return rawUrl;

  final origin = api.replace(path: '', query: null, fragment: null);

  final path = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';

  return origin.replace(path: path).toString();
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().toLowerCase();
  return text == '1' || text == 'true';
}

String? _nullable(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
