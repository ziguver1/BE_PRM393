import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/home_provider.dart';
import '../../../core/widgets/product_card.dart';

class RecommendedGrid extends ConsumerWidget {
  const RecommendedGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final popularAsync = ref.watch(homePopularProductsProvider);

    return popularAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                heroTagSuffix: 'recommended',
                onTap: () => context.push(
                  '/product/${product.productId}?heroTag=product-img-${product.productId}recommended',
                  extra: product,
                ),
              );
            },
            childCount: products.length,
          ),
        );
      },
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              height: index.isEven ? 240 : 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          childCount: 4,
        ),
      ),
      error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}
