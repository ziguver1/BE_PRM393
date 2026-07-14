import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../presentation/home/providers/home_provider.dart';
import 'product_detail_screen.dart';

/// Wraps [ProductDetailScreen] with async product loading by [productId].
/// Used when navigating without passing [extra], e.g. from Home, Search, Category.
class ProductDetailLoader extends ConsumerWidget {
  final int productId;
  /// Optional pre-loaded product from list — used as initial value to avoid delay.
  final ProductModel? initialProduct;

  const ProductDetailLoader({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If we already have a fully-loaded ProductModel (passed via extra), use it directly
    if (initialProduct != null) {
      return ProductDetailScreen(product: initialProduct!);
    }

    final productAsync = ref.watch(productDetailProvider(productId));

    return productAsync.when(
      data: (product) => ProductDetailScreen(product: product),
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Đang tải thông tin sản phẩm...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không thể tải sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(productDetailProvider(productId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
