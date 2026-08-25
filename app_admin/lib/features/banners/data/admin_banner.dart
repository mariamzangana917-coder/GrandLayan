class AdminBanner {
  const AdminBanner({
    required this.id,
    required this.imageUrl,
    required this.placement,
    required this.actionType,
    required this.sortOrder,
    required this.isActive,
    this.title,
    this.subtitle,
    this.actionTargetId,
    this.externalUrl,
  });

  final int id;
  final String imageUrl;
  final String placement;
  final String actionType;
  final int sortOrder;
  final bool isActive;
  final String? title;
  final String? subtitle;
  final int? actionTargetId;
  final String? externalUrl;

  factory AdminBanner.fromJson(Map<String, dynamic> json) => AdminBanner(
        id: _int(json['id']),
        imageUrl: json['image_url']?.toString() ?? '',
        placement: json['placement']?.toString() ?? 'home',
        actionType: json['action_type']?.toString() ?? 'none',
        sortOrder: _int(json['sort_order']),
        isActive: _bool(json['is_active']),
        title: _text(json['title']),
        subtitle: _text(json['subtitle']),
        actionTargetId: json['action_target_id'] == null ? null : _int(json['action_target_id']),
        externalUrl: _text(json['external_url']),
      );

  static int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
  static bool _bool(dynamic value) => value == true || value == 1 || '$value' == '1' || '$value'.toLowerCase() == 'true';
  static String? _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
