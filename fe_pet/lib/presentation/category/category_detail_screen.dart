import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/product_model.dart';
import '../../core/configs/providers.dart';

// Family provider to load category products
// Use datasource directly to get ProductModel with full relations (images, variants, filters)
final categoryProductsProvider = FutureProvider.family<List<ProductModel>, int>(
  (ref, catId) async {
    final dataSource = ref.watch(productRemoteDataSourceProvider);
    final result = await dataSource.getProducts(
      page: 1,
      limit: 50,
      categoryId: catId,
    );
    return result.data;
  },
);

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  Future<void> _onRefresh() async {
    ref.invalidate(categoryProductsProvider(widget.categoryId));
  }

  List<ProductModel> _sortProducts(List<ProductModel> products) {
    final sorted = List<ProductModel>.from(products);
    if (_sortBy == 'price') {
      if (_sortOrder == 'asc') {
        sorted.sort((a, b) => a.price.compareTo(b.price));
      } else {
        sorted.sort((a, b) => b.price.compareTo(a.price));
      }
    } else if (_sortBy == 'name') {
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else {
      // createdAt sort - newest first
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(
      categoryProductsProvider(widget.categoryId),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () {
              _showSortBottomSheet(isDark);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có sản phẩm nào',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng quay lại sau.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            final sortedProducts = _sortProducts(products);

            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.m),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.64,
                crossAxisSpacing: AppSpacing.m,
                mainAxisSpacing: AppSpacing.m,
              ),
              itemCount: sortedProducts.length,
              itemBuilder: (context, index) {
                final product = sortedProducts[index];
                return ProductCard(
                  product: product,
                  heroTagSuffix: 'category',
                  onTap: () => context.push(
                    '/product/${product.productId}?heroTag=product-img-${product.productId}category',
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

  void _showSortBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sắp xếp sản phẩm',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.m),
              ListTile(
                leading: const Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Mới nhất'),
                trailing: _sortBy == 'createdAt'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'createdAt';
                    _sortOrder = 'desc';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.arrow_downward_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Giá: Thấp đến Cao'),
                trailing: _sortBy == 'price' && _sortOrder == 'asc'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'price';
                    _sortOrder = 'asc';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.arrow_upward_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Giá: Cao đến Thấp'),
                trailing: _sortBy == 'price' && _sortOrder == 'desc'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'price';
                    _sortOrder = 'desc';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.sort_by_alpha_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Tên sản phẩm (A-Z)'),
                trailing: _sortBy == 'name'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'name';
                    _sortOrder = 'asc';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
