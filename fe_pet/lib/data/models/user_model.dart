import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.userId,
    required super.fullName,
    required super.email,
    super.phone,
    super.avatar,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['UserId'] as int,
      fullName: json['FullName'] as String,
      email: json['Email'] as String,
      phone: json['Phone'] as String?,
      avatar: json['Avatar'] as String?,
      role: json['Role'] as String? ?? 'CUSTOMER',
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
    };
  }
}
