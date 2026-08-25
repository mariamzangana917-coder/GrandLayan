class ManagerProfile {
  const ManagerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatar;

  factory ManagerProfile.fromJson(Map<String, dynamic> json) {
    final Object? rawId = json['id'];
    final int? id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');

    final String? name = _readRequiredString(json['name']);
    final String? email = _readRequiredString(json['email']);
    final String? phone = _readRequiredString(json['phone']);
    final String role = _readRequiredString(json['role']) ?? 'manager';
    final String? avatar = _readOptionalString(json['avatar']);

    if (id == null || name == null || email == null || phone == null) {
      throw const FormatException('بيانات حساب المديرة المستلمة غير صالحة.');
    }

    return ManagerProfile(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      avatar: avatar,
    );
  }

  ManagerProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatar,
    bool clearAvatar = false,
  }) {
    return ManagerProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: clearAvatar ? null : avatar ?? this.avatar,
    );
  }

  static String? _readRequiredString(Object? value) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }

  static String? _readOptionalString(Object? value) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }
}
