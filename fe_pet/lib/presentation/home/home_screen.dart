import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'providers/home_provider.dart';

// Reusable custom widgets
import 'widgets/home_header.dart';
import 'widgets/promotion_carousel.dart';
import 'widgets/quick_service_list.dart';
import 'widgets/category_list_chips.dart';
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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Home Header Greet
              const SliverToBoxAdapter(
                child: HomeHeader(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),

              // 3. Promotion Slide Banner
              const SliverToBoxAdapter(
                child: PromotionCarousel(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),

              // 4. Quick Services Horizontal Cards
              const SliverToBoxAdapter(
                child: QuickServiceList(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),

              // 5. Popular Categories
              const SliverToBoxAdapter(
                child: CategoryListChips(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),

              // 6. Flash Sale Gradients & Countdown
              const SliverToBoxAdapter(
                child: FlashSale(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),

              // 7. Featured Products List Horizontal
              const SliverToBoxAdapter(
                child: FeaturedProductsList(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),

              // 8. Recommended Grid Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Gợi ý cho bạn',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 12),
              ),

              // 9. Recommended Grid Products (SliverGrid)
              const RecommendedGrid(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),

              // 10. Pet Tips Blog Section
              const SliverToBoxAdapter(
                child: PetTips(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
