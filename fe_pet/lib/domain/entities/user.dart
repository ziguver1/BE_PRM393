class User {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;

  const User({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
  });

  bool get isAdmin => role == 'ADMIN';
}
