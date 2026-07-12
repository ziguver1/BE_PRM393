import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthLocalDataSource {
  final SharedPreferences _prefs;

  AuthLocalDataSource(this._prefs);

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_data';

  Future<bool> saveAccessToken(String token) async {
    return await _prefs.setString(_keyAccessToken, token);
  }

  String? getAccessToken() {
    return _prefs.getString(_keyAccessToken);
  }

  Future<bool> saveRefreshToken(String token) async {
    return await _prefs.setString(_keyRefreshToken, token);
  }

  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  Future<bool> saveUser(UserModel user) async {
    return await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final userStr = _prefs.getString(_keyUser);
    if (userStr != null) {
      try {
        return UserModel.fromJson(jsonDecode(userStr) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<bool> clearSession() async {
    final t1 = await _prefs.remove(_keyAccessToken);
    final t2 = await _prefs.remove(_keyRefreshToken);
    final t3 = await _prefs.remove(_keyUser);
    return t1 && t2 && t3;
  }
}
