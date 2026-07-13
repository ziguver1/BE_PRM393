import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Premium Orange Gradient Header
            _buildPremiumHeader(context, user, isDark),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 2. Shopee-like "Đơn hàng của tôi" Card
                  _buildMyOrdersCard(context, isDark),

                  const SizedBox(height: 16),

                  // 3. Settings Menu Card
                  Material(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDark ? AppColors.borderDark : Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Sổ địa chỉ',
                          subtitle: 'Quản lý các địa chỉ nhận hàng của bạn',
                          onTap: () => context.push('/profile/addresses'),
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildMenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Đổi mật khẩu',
                          subtitle: 'Cập nhật lại mật khẩu tài khoản',
                          onTap: () => context.push('/profile/change-password'),
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildMenuItem(
                          icon: Icons.logout_rounded,
                          title: 'Đăng xuất',
                          subtitle: 'Thoát khỏi phiên làm việc hiện tại',
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
                          isDark: isDark,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, dynamic user, bool isDark) {
    final String fullName = user?.fullName ?? 'Khách hàng';
    final String initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
    final String email = user?.email ?? 'Chưa đăng nhập';
    final bool isAdmin = user?.role == 'ADMIN';
    final String memberGrade = isAdmin ? 'Thành viên Kim cương' : 'Thành viên Bạc';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.surfaceDark, AppColors.backgroundDark]
              : [Colors.orange.shade800, Colors.orange.shade500],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 64, bottom: 32),
      child: Row(
        children: [
          // Premium Avatar
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // User details & Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),

                // Member Grade Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.military_tech_rounded,
                        color: Colors.amberAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        memberGrade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyOrdersCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 0.5,
      color: isDark ? AppColors.surfaceDark : Colors.white,
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
            // Card Title Header
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
                          'Xem lịch sử mua hàng',
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
            const SizedBox(height: 16),

            // Horizontal Status Icon Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderStatusItem(
                  context,
                  icon: Icons.wallet_giftcard_rounded,
                  label: 'Chờ xác nhận',
                ),
                _buildOrderStatusItem(
                  context,
                  icon: Icons.archive_outlined,
                  label: 'Chờ lấy hàng',
                ),
                _buildOrderStatusItem(
                  context,
                  icon: Icons.local_shipping_outlined,
                  label: 'Đang giao',
                ),
                _buildOrderStatusItem(
                  context,
                  icon: Icons.star_outline_rounded,
                  label: 'Đánh giá',
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
  }) {
    return InkWell(
      onTap: () => context.push('/orders'),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.orange.shade800,
              size: 26,
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
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final titleColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDestructive ? AppColors.error : AppColors.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.grey[700] : Colors.grey[400],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: isDark ? AppColors.borderDark : Colors.grey[200]!,
    );
  }
}
