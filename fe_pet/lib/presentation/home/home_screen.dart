import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider_pkg;
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
    );
  }
}
