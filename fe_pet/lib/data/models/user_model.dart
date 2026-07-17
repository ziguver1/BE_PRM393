import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.userId,
    required super.fullName,
    required super.email,
    super.phone,
    super.avatar,
    required super.role,
    super.gender,
    super.birthday,
    super.bio,
    super.conversationId,
    super.unreadSupportMessages,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? bday;
    if (json['birthday'] != null) {
      try {
        bday = DateTime.parse(json['birthday'].toString());
      } catch (_) {}
    } else if (json['Birthday'] != null) {
      try {
        bday = DateTime.parse(json['Birthday'].toString());
      } catch (_) {}
    }

    return UserModel(
      userId: json['UserId'] ?? json['id'] ?? 0,
      fullName: json['FullName'] ?? json['fullName'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      phone: json['Phone'] ?? json['phoneNumber'] ?? json['phone'],
      avatar: json['Avatar'] ?? json['avatar'],
      role: json['Role'] ?? json['role'] ?? 'CUSTOMER',
      gender: json['gender'] ?? json['Gender'],
      birthday: bday,
      bio: json['bio'] ?? json['Bio'],
      conversationId: json['conversationId'] ?? json['ConversationId'],
      unreadSupportMessages: json['unreadSupportMessages'] ?? json['unreadCustomer'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'FullName': fullName,
      'Email': email,
      'Phone': phone,
      'Avatar': avatar,
      'Role': role,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'bio': bio,
      'conversationId': conversationId,
      'unreadSupportMessages': unreadSupportMessages,
    };
  }
}
