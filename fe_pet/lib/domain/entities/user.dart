class User {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final String? gender;
  final DateTime? birthday;
  final String? bio;
  final int? conversationId;
  final int unreadSupportMessages;

  const User({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    this.gender,
    this.birthday,
    this.bio,
    this.conversationId,
    this.unreadSupportMessages = 0,
  });

  bool get isAdmin => role == 'ADMIN';

  User copyWith({
    int? userId,
    String? fullName,
    String? email,
    String? phone,
    String? avatar,
    String? role,
    String? gender,
    DateTime? birthday,
    String? bio,
    int? conversationId,
    int? unreadSupportMessages,
  }) {
    return User(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      bio: bio ?? this.bio,
      conversationId: conversationId ?? this.conversationId,
      unreadSupportMessages: unreadSupportMessages ?? this.unreadSupportMessages,
    );
  }
}
