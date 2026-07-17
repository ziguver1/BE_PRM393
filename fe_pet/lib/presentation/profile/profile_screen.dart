import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../auth/providers/auth_provider.dart';
import './providers/profile_provider.dart';
import '../../domain/entities/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int? _pendingCount;
  int? _shippingCount;
  int? _receivedCount;
  int? _cancelledCount;
  bool _isLoadingCounts = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderCounts();
  }

  Future<void> _fetchOrderCounts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCounts = true;
    });

    try {
      final response = await ApiClient().dio.get('/orders');
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> orders = response.data;
        int pending = 0;
        int shipping = 0;
        int received = 0;
        int cancelled = 0;

        for (var o in orders) {
          final status = (o['Status']?.toString() ?? '').toUpperCase();
          if (status == 'PENDING') {
            pending++;
          } else if (status == 'PAID' || status == 'SHIPPING' || status == 'DELIVERED') {
            shipping++;
          } else if (status == 'RECEIVED') {
            received++;
          } else if (status == 'CANCELLED') {
            cancelled++;
          }
        }

        if (mounted) {
          setState(() {
            _pendingCount = pending;
            _shippingCount = shipping;
            _receivedCount = received;
            _cancelledCount = cancelled;
            _isLoadingCounts = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingCounts = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching order counts: $e');
      if (mounted) {
        setState(() {
          _isLoadingCounts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchOrderCounts();
          ref.read(profileNotifierProvider.notifier).refresh();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 1. Premium Streamlined Orange Gradient Header
              _buildPremiumHeader(context, user, isDark),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // 2. Order Summary Card
                    _buildMyOrdersCard(context, isDark),

                    const SizedBox(height: 24),

                    // 3. Edit Profile Action Card
                    _buildEditProfileCard(context, isDark),

                    const SizedBox(height: 16),

                    // 4. Customer Support Action Card
                    _buildCustomerSupportCard(context, user, isDark),

                    const SizedBox(height: 16),

                    // 5. Logout Section
                    _buildLogoutCard(context, isDark),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, User? user, bool isDark) {
    final String fullName = user?.fullName ?? 'Khách hàng';
    final String initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
    final String email = user?.email ?? 'Chưa đăng nhập';
    final String? phone = user?.phone;
    final String? avatar = user?.avatar;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.surfaceDark, AppColors.backgroundDark]
              : [Colors.orange.shade800, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 24),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ClipOval(
              child: avatar != null && avatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileCard(BuildContext context, bool isDark) {
    return PressableCard(
      onTap: () => context.push('/profile/edit'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade800.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.orange.shade800,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chỉnh sửa thông tin',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cập nhật họ tên, ngày sinh, số điện thoại...',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSupportCard(BuildContext context, User? user, bool isDark) {
    final unreadCount = user?.unreadSupportMessages ?? 0;

    return PressableCard(
      onTap: () => context.push('/chat'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade800.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.orange.shade800,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Hỗ trợ khách hàng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Trò chuyện hỗ trợ 24/7',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrdersCard(BuildContext context, bool isDark) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đơn hàng của tôi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/orders'),
                    child: const Row(
                      children: [
                        Text(
                          'Xem lịch sử',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? AppColors.borderDark : Colors.grey[100]!, height: 1),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderStatusItem(
                  context,
                  icon: Icons.payment_rounded,
                  label: 'Chờ thanh toán',
                  tabIndex: 1,
                  count: _pendingCount,
                ),
                _buildOrderStatusItem(
                  context,
                  icon: Icons.local_shipping_outlined,
                  label: 'Đang giao',
                  tabIndex: 2,
                  count: _shippingCount,
                ),
                _buildOrderStatusItem(
                  context,
                  icon: Icons.done_all_rounded,
                  label: 'Đã nhận',
                  tabIndex: 3,
                  count: _receivedCount,
                ),
                _buildOrderStatusItem(
                  context,
                  icon: Icons.cancel_outlined,
                  label: 'Đã hủy',
                  tabIndex: 4,
                  count: _cancelledCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int tabIndex,
    required int? count,
  }) {
    return InkWell(
      onTap: () => context.push('/orders?tab=$tabIndex'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          width: 80,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: Colors.orange.shade800,
                    size: 26,
                  ),
                  _buildCountBadge(count),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(int? count) {
    if (_isLoadingCounts || count == null || count <= 0) return const SizedBox.shrink();
    return Positioned(
      top: -4,
      right: -8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: const BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, bool isDark) {
    return PressableCard(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Xác nhận đăng xuất'),
            content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await ref.read(authNotifierProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Đăng xuất khỏi tài khoản của bạn',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final double borderRadius;
  final double elevation;

  const PressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.borderRadius = 20.0,
    this.elevation = 0.5,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.96);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Material(
          color: widget.color ?? (isDark ? AppColors.surfaceDark : Colors.white),
          elevation: widget.elevation,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : Colors.grey[200]!,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        ),
      ),
    );
  }
}
