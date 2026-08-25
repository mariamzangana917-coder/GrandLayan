class CustomerUser {
  const CustomerUser({
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
  final String? avatar;
  final String role;

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final name = json['name'];
    final email = json['email'];
    final phone = json['phone'];
    final role = json['role'];
    final avatar = json['avatar'];

    if (id == null ||
        name is! String ||
        email is! String ||
        phone is! String ||
        role is! String) {
      throw const FormatException('بيانات المستخدم المستلمة غير صالحة.');
    }

    return CustomerUser(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      avatar: avatar?.toString(),
    );
  }
}
