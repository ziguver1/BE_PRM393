import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
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
            // 1. Collapsible Premium Shopee-like SliverAppBar
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: false,
              elevation: 0,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
              expandedHeight: 110,
              title: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => context.push('/search'),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tìm hạt, cát, pate cho thú cưng...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  tooltip: 'Thông báo',
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppColors.surfaceDark, AppColors.backgroundDark]
                          : [AppColors.primary, AppColors.primary.withOpacity(0.85)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 74),
                  child: const Row(
                    children: [
                      Text(
                        'Chào mừng bạn đến với PawMart 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
