class CustomerBanner {
  const CustomerBanner({required this.id, required this.imageUrl, required this.placement, required this.actionType, this.title, this.subtitle, this.actionTargetId});
  final int id; final String imageUrl; final String placement; final String actionType; final String? title; final String? subtitle; final int? actionTargetId;
  factory CustomerBanner.fromJson(Map<String, dynamic> json) => CustomerBanner(
    id: _int(json['id']), imageUrl: json['image_url']?.toString() ?? '', placement: json['placement']?.toString() ?? 'home', actionType: json['action_type']?.toString() ?? 'none', title: _text(json['title']), subtitle: _text(json['subtitle']), actionTargetId: json['action_target_id'] == null ? null : _int(json['action_target_id']),
  );
  static int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
  static String? _text(dynamic value) { final text = value?.toString().trim() ?? ''; return text.isEmpty ? null : text; }
}
