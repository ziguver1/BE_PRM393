import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/network/api_client.dart';
import '../presentation/order/order_detail_screen.dart';
import '../presentation/order/order_tracking_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    // 1. Request notification permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: Notification permission granted.');
    } else {
      debugPrint('FCM: Notification permission denied.');
    }

    // 2. Listen to token refresh
    _fcm.onTokenRefresh.listen((token) {
      debugPrint('FCM: Token refreshed: $token');
      _uploadToken(token);
    });

    // 3. Handle messages in Foreground state
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM: Foreground message received: ${message.notification?.title}');
      if (context.mounted) {
        _showForegroundSnackBar(context, message);
      }
    });

    // 4. Handle notifications tapped in Background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: Message opened app: ${message.data}');
      if (context.mounted) {
        _handleNotificationClick(context, message.data);
      }
    });

    // 5. Check if app was launched from Terminated state via a notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM: Initial message found: ${initialMessage.data}');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          _handleNotificationClick(context, initialMessage.data);
        }
      });
    }

    _isInitialized = true;
    
    // Upload current FCM token immediately if user is already authenticated
    try {
      final token = await _fcm.getToken(
        vapidKey: kIsWeb ? 'BHQLsAlReL4dk0XRI1BfRy_3s1Y57L5lmWoWGBAy3sTwcJSe_jzA3_udpDq5LDWza0hJOvIgax_Wip09b4BUuLE' : null,
      );
      if (token != null) {
        debugPrint('FCM: Current Token: $token');
        _uploadToken(token);
      }
    } catch (e) {
      debugPrint('FCM: Failed to get current token: $e');
    }
  }

  Future<void> _uploadToken(String token) async {
    final currentToken = ApiClient().token;
    if (currentToken == null || currentToken.isEmpty) {
      debugPrint('FCM: User not authenticated. Skipping token upload.');
      return;
    }

    try {
      final response = await ApiClient().dio.put(
        '/auth/fcm-token',
        data: {'fcmToken': token},
      );
      if (response.statusCode == 200) {
        debugPrint('FCM: Device Token uploaded successfully.');
      }
    } catch (e) {
      debugPrint('FCM: Failed to upload Device Token to server: $e');
    }
  }

  Future<void> clearToken() async {
    try {
      final currentToken = ApiClient().token;
      if (currentToken != null && currentToken.isNotEmpty) {
        await ApiClient().dio.put(
          '/auth/fcm-token',
          data: {'fcmToken': null},
        );
        debugPrint('FCM: Token cleared on backend successfully.');
      }
    } catch (e) {
      debugPrint('FCM: Failed to clear token on backend: $e');
    } finally {
      try {
        await _fcm.deleteToken();
        debugPrint('FCM: Token deleted on device.');
      } catch (e) {
        debugPrint('FCM: Failed to delete token on device: $e');
      }
    }
  }

  void _showForegroundSnackBar(BuildContext context, RemoteMessage message) {
    final title = message.notification?.title ?? 'Thông báo';
    final body = message.notification?.body ?? '';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty) Text(body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            _handleNotificationClick(context, message.data);
          },
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleNotificationClick(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final orderIdStr = data['orderId'] as String?;
    if (type == null || orderIdStr == null) return;
    
    final orderId = int.tryParse(orderIdStr);
    if (orderId == null) return;

    // SCALABLE ROUTING LOGIC: Switch case handles notifications strictly based on type
    switch (type) {
      case 'ORDER_SHIPPING_STARTED':
        _fetchAndRouteOrder(context, orderId, type);
        break;
        
      case 'ORDER_DELIVERED':
        _fetchAndRouteOrder(context, orderId, type);
        break;
        
      default:
        debugPrint('FCM: Unknown notification type: $type');
        break;
    }
  }

  Future<void> _fetchAndRouteOrder(BuildContext context, int orderId, String type) async {
    try {
      final response = await ApiClient().dio.get('/orders/$orderId');
      if (response.statusCode == 200) {
        final order = response.data;
        if (!context.mounted) return;

        if (type == 'ORDER_SHIPPING_STARTED') {
          final routePointsData = order['RoutePoints'] as List<dynamic>?;
          if (routePointsData != null && routePointsData.isNotEmpty) {
            final routePoints = routePointsData
                .map((e) => LatLng(e['lat'] as double, e['lng'] as double))
                .toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderTrackingScreen(
                  routePoints: routePoints,
                  orderId: orderId,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: order),
              ),
            );
          }
        } else if (type == 'ORDER_DELIVERED') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('FCM: Failed to fetch order detail for navigation routing: $e');
    }
  }
}
