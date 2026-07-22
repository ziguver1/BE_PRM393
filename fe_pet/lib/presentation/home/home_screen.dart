import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import 'providers/home_provider.dart';

// Reusable custom widgets
import 'widgets/promotion_carousel.dart';
import 'widgets/category_grid_widget.dart';
import 'widgets/flash_sale.dart';
import 'widgets/featured_products_list.dart';
import 'widgets/recommended_grid.dart';
import 'widgets/pet_tips.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(homeCategoriesProvider);
    ref.invalidate(homeFeaturedProductsProvider);
    ref.invalidate(homePopularProductsProvider);
  }

  void _showShopInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Title and Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28),
                        SizedBox(width: 8),
                        Text('PetShop Xin Chào!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Description and Address Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chào mừng bạn đến với PetShop! Chúng tôi tự hào mang đến không gian mua sắm lý tưởng với các sản phẩm thức ăn, phụ kiện cao cấp và dịch vụ chăm sóc thú cưng chuẩn 5 sao. Sự hài lòng của các "boss" nhỏ là niềm vui lớn nhất của chúng tôi!',
                      style: TextStyle(height: 1.5, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.location_on, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Chi nhánh 1 (Trụ sở chính)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Lô E2a-7, Đường D1 Khu Công nghệ cao,\nP. Long Thạnh Mỹ, TP. Thủ Đức, TP. HCM',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Full-width Map at the bottom
              SizedBox(
                height: 220,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(10.8411276, 106.809883),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fe_pet',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: const LatLng(10.8411276, 106.809883),
                          width: 100,
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'PETSHOP',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const Icon(Icons.location_on, color: AppColors.primary, size: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5), // Premium light gray background
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                tooltip: 'Thông tin Shop',
                onPressed: () => _showShopInfo(context),
              ),
              toolbarHeight: 80, // Elevated toolbar height to let the logo breathe
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
              title: Hero(
                tag: 'pets-logo',
                child: Image.asset(
                  'public/images/pets_logo.png',
                  height: 75, // Zoomed in to capture the primary space
                  fit: BoxFit.contain,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppColors.surfaceDark, AppColors.backgroundDark]
                          : [Colors.orange.shade50, AppColors.primary], 
                      begin: Alignment.topLeft,     
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              actions: [
                // Wishlist Button (Trái tim)
                IconButton(
                  onPressed: () => context.push('/wishlist'),
                  icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
                  tooltip: 'Yêu thích',
                ),
                // Notification Button (Chuông)
                provider_pkg.Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    final count = provider.unreadCount;
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                          tooltip: 'Thông báo',
                        ),
                        if (count > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 2. Promotion Slide Banner
            const SliverToBoxAdapter(child: PromotionCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 3. Category Grid horizontally scrollable (2 rows)
            const SliverToBoxAdapter(child: CategoryGridWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 4. Flash Sale Gradients & Countdown
            const SliverToBoxAdapter(child: FlashSale()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 5. Featured Products List Horizontal
            const SliverToBoxAdapter(child: FeaturedProductsList()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 6. Recommended Grid Header ("Gợi ý hôm nay")
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gợi ý hôm nay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: isDark ? Colors.white : const Color(0xFF2F2F2F),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HOT',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 7. Recommended Masonry Grid Products (SliverMasonryGrid)
            const RecommendedGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 8. Pet Tips Blog Section
            const SliverToBoxAdapter(child: PetTips()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-chat'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          'Hỏi AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
