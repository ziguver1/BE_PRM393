import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final response = await ApiClient().dio.put('/notifications/$notificationId/read');
      if (response.statusCode == 200) {
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).markAsReadLocally(notificationId);
        }
      }
    } catch (e) {
      debugPrint('Lỗi đánh dấu đã đọc: $e');
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getNotificationIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('giao') || t.contains('shipping') || t.contains('delivered')) {
      return Icons.local_shipping_outlined;
    }
    if (t.contains('huỷ') || t.contains('cancel')) {
      return Icons.cancel_outlined;
    }
    if (t.contains('thanh toán') || t.contains('pay')) {
      return Icons.payment_outlined;
    }
    return Icons.notifications_none_outlined;
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('đang giao')) {
      return Colors.blue;
    }
    if (t.contains('đã giao')) {
      return Colors.green;
    }
    if (t.contains('huỷ')) {
      return Colors.red;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thông báo của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notificationProvider.fetchNotifications(),
          ),
        ],
      ),
      body: notificationProvider.isLoading && notificationProvider.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : notificationProvider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_off_outlined,
                          size: 50,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bạn chưa có thông báo nào!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notificationProvider.notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = notificationProvider.notifications[index];
                    final id = notification['NotificationId'] as int;
                    final title = notification['Title'] as String? ?? 'Thông báo';
                    final content = notification['Content'] as String? ?? '';
                    final isRead = notification['IsRead'] as bool? ?? false;
                    final date = notification['CreatedAt'] as String;

                    return InkWell(
                      onTap: () {
                        if (!isRead) {
                          _markAsRead(id);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead
                              ? (isDark ? AppColors.surfaceDark : Colors.white)
                              : (isDark
                                  ? AppColors.primary.withOpacity(0.05)
                                  : AppColors.primary.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isRead
                                ? AppColors.primary.withOpacity(0.3)
                                : (isDark ? AppColors.borderDark : AppColors.border),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getIconColor(title).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getNotificationIcon(title),
                                color: _getIconColor(title),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontWeight: !isRead ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 14,
                                            color: !isRead
                                                ? (isDark ? Colors.white : Colors.black)
                                                : (isDark ? Colors.grey[400] : Colors.grey[800]),
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    content,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(date),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
