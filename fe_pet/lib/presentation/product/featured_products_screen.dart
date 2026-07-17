import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/product_card.dart';
import '../home/providers/home_provider.dart';

class FeaturedProductsScreen extends ConsumerStatefulWidget {
  const FeaturedProductsScreen({super.key});

  @override
  ConsumerState<FeaturedProductsScreen> createState() =>
      _FeaturedProductsScreenState();
}

class _FeaturedProductsScreenState
    extends ConsumerState<FeaturedProductsScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(homeFeaturedProductsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featuredAsync = ref.watch(homeFeaturedProductsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: const Text('Sản phẩm nổi bật'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: featuredAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Text(
                  'Chưa có sản phẩm nổi bật.',
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.m),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // More compact card frame for 2-column layout.
                childAspectRatio: 0.64,
                crossAxisSpacing: AppSpacing.m,
                mainAxisSpacing: AppSpacing.m,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  heroTagSuffix: 'featuredAll',
                  onTap: () => context.push(
                    '/product/${product.productId}?heroTag=product-img-${product.productId}featuredAll',
                    extra: product,
                  ),
                );
              },
            );
          },
          loading: () => GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.64,
              crossAxisSpacing: AppSpacing.m,
              mainAxisSpacing: AppSpacing.m,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Container(),
              ),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Lỗi tải sản phẩm: ${err.toString()}',
                style: AppTextStyles.bodyLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
