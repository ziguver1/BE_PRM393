import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    try {
      _isLoading = true;
      final response = await ApiClient().dio.get('/notifications');
      if (response.statusCode == 200) {
        _notifications = response.data as List<dynamic>;
        _unreadCount = _notifications.where((n) => n['IsRead'] == false).length;
      }
    } catch (e) {
      debugPrint('FCM Provider: Failed to fetch notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }
  
  void markAsReadLocally(int notificationId) {
    final index = _notifications.indexWhere((n) => n['NotificationId'] == notificationId);
    if (index != -1 && _notifications[index]['IsRead'] == false) {
      _notifications[index]['IsRead'] = true;
      _unreadCount = _notifications.where((n) => n['IsRead'] == false).length;
      notifyListeners();
    }
  }
  
  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}
