import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/product_card.dart';
import '../home/providers/home_provider.dart';
import 'providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Trigger initial search empty query
    Future.microtask(() {
      ref.read(searchProvider.notifier).executeSearch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).executeSearch(loadMore: true);
    }
  }

  void _showFilterBottomSheet() {
    final searchState = ref.read(searchProvider);
    final categoriesAsync = ref.read(homeCategoriesProvider);

    double? localMin = searchState.minPrice;
    double? localMax = searchState.maxPrice;
    int? localCategoryId = searchState.categoryId;
    String localSortBy = searchState.sortBy;
    String localSortOrder = searchState.sortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bộ lọc & Sắp xếp',
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                localMin = null;
                                localMax = null;
                                localCategoryId = null;
                                localSortBy = 'createdAt';
                                localSortOrder = 'desc';
                              });
                            },
                            child: const Text(
                              'Đặt lại',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Categories filter
                      Text(
                        'Danh Mục',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      categoriesAsync.when(
                        data: (categories) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: localCategoryId == null,
                                selectedColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setModalState(() => localCategoryId = null);
                                  }
                                },
                              ),
                              ...categories.map(
                                (cat) => ChoiceChip(
                                  label: Text(cat.name),
                                  selected: localCategoryId == cat.categoryId,
                                  selectedColor: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  onSelected: (sel) {
                                    if (sel) {
                                      setModalState(
                                        () => localCategoryId = cat.categoryId,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // Pricing Range Filter
                      Text(
                        'Khoảng giá (\$)',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Thấp nhất',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              controller: TextEditingController(
                                text: localMin?.toString() ?? '',
                              ),
                              onChanged: (val) {
                                localMin = double.tryParse(val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Cao nhất',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              controller: TextEditingController(
                                text: localMax?.toString() ?? '',
                              ),
                              onChanged: (val) {
                                localMax = double.tryParse(val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sorting Options
                      Text(
                        'Sắp xếp theo',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: '$localSortBy-$localSortOrder',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'createdAt-desc',
                            child: Text('Mới nhất'),
                          ),
                          DropdownMenuItem(
                            value: 'price-asc',
                            child: Text('Giá: Thấp -> Cao'),
                          ),
                          DropdownMenuItem(
                            value: 'price-desc',
                            child: Text('Giá: Cao -> Thấp'),
                          ),
                          DropdownMenuItem(
                            value: 'name-asc',
                            child: Text('Tên: A -> Z'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            final split = val.split('-');
                            localSortBy = split[0];
                            localSortOrder = split[1];
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Apply button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(searchProvider.notifier)
                              .updateCategory(localCategoryId);
                          ref
                              .read(searchProvider.notifier)
                              .updateFilters(
                                minPrice: localMin,
                                maxPrice: localMax,
                                sortBy: localSortBy,
                                sortOrder: localSortOrder,
                              );
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Áp dụng bộ lọc',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm sản phẩm'), centerTitle: true),
      body: Column(
        children: [
          // Search & Filter input bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên sản phẩm cần tìm...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(searchProvider.notifier)
                                    .updateQuery('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                    onSubmitted: (val) {
                      ref.read(searchProvider.notifier).updateQuery(val);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                // Filter Button
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Badge(
                      isLabelVisible:
                          searchState.categoryId != null ||
                          searchState.minPrice != null ||
                          searchState.maxPrice != null ||
                          searchState.sortBy != 'createdAt',
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters status row
          if (searchState.categoryId != null ||
              searchState.minPrice != null ||
              searchState.maxPrice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Row(
                children: [
                  Text(
                    'Đang áp dụng bộ lọc',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(searchProvider.notifier).clearFilters();
                    },
                    child: Text(
                      'Xoá bộ lọc',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Result grid or loaders
          Expanded(
            child: searchState.isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.64,
                          crossAxisSpacing: AppSpacing.m,
                          mainAxisSpacing: AppSpacing.m,
                        ),
                    itemCount: 6,
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDark
                          ? Colors.grey[700]!
                          : Colors.grey[100]!,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                        child: Container(),
                      ),
                    ),
                  )
                : searchState.products.isEmpty
                ? Center(
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
                            Icons.search_off_rounded,
                            size: 72,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy sản phẩm',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy thử thay đổi từ khoá hoặc bộ lọc.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppSpacing.m),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.64,
                                crossAxisSpacing: AppSpacing.m,
                                mainAxisSpacing: AppSpacing.m,
                              ),
                          itemCount: searchState.products.length,
                          itemBuilder: (context, index) {
                            final product = searchState.products[index];
                            return ProductCard(
                              product: product,
                              heroTagSuffix: 'search',
                              onTap: () => context.push(
                                '/product/${product.productId}?heroTag=product-img-${product.productId}search',
                                extra: product,
                              ),
                            );
                          },
                        ),
                      ),
                      // Loading more indicator
                      if (searchState.isLoadMore)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.s),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
