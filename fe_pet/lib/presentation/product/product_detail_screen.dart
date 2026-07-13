import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../domain/entities/product.dart';
import '../../core/configs/providers.dart';
import '../../providers/cart_provider.dart';

// Provider to fetch single product details
final productDetailProvider = FutureProvider.family<Product, int>((
  ref,
  id,
) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(id);
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedVariantIndex = 0;
  bool _isAddingToCart = false;
  late final CartProvider _cartProvider;

  @override
  void initState() {
    super.initState();
    _cartProvider = CartProvider();
  }

  String _formatCurrency(double value) {
    final raw = value.toStringAsFixed(0);
    final chars = raw.split('');
    for (var i = chars.length - 3; i > 0; i -= 3) {
      chars.insert(i, '.');
    }
    return '${chars.join()}đ';
  }

  bool _isDescriptionExpanded = false;
  bool _isFavorite = false;


  final List<Map<String, dynamic>> _nutritionHighlights = [
    {
      'label': 'Giàu Protein',
      'desc': '32% Đạm thô',
      'icon': Icons.restaurant_rounded,
      'color': Colors.orange,
    },
    {
      'label': 'Vitamin C',
      'desc': 'Tăng đề kháng',
      'icon': Icons.spa_rounded,
      'color': Colors.green,
    },
    {
      'label': 'Không Chất Độn',
      'desc': '100% Tự nhiên',
      'icon': Icons.health_and_safety_rounded,
      'color': Colors.blue,
    },
    {
      'label': 'Dễ Tiêu Hoá',
      'desc': 'Thêm Prebiotics',
      'icon': Icons.healing_rounded,
      'color': Colors.purple,
    },
  ];

  Product _getFallbackProduct() {
    return Product(
      productId: widget.productId,
      categoryId: 1,
      name: 'Thức Ăn Hạt Hữu Cơ Cao Cấp Royal Canin cho Cún',
      description:
          'Thức ăn hạt hữu cơ dinh dưỡng chất lượng cao cung cấp đầy đủ dưỡng chất cần thiết cho sự phát triển toàn diện của thú cưng của bạn. Công thức đặc biệt được nghiên cứu bởi các chuyên gia thú y hàng đầu giúp lông bóng mượt, hệ tiêu hoá khoẻ mạnh và tăng cường sức đề kháng cho cún cưng. Sản phẩm cam kết không chứa chất bảo quản nhân tạo, không hương liệu hoá học và 100% nguyên liệu tự nhiên chọn lọc từ nông trại organic.',
      price: 29.99,
      stock: 15,
      imageUrl:
          'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=500&auto=format&fit=crop&q=60',
      createdAt: DateTime.now(),
    );
  }

  void _onFavoriteToggle() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? 'Đã thêm vào danh sách yêu thích!'
              : 'Đã xoá khỏi danh sách yêu thích!',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    final hasVariants = product.variants != null && product.variants!.isNotEmpty;
    final selectedVariant = hasVariants && _selectedVariantIndex < product.variants!.length
        ? product.variants![_selectedVariantIndex].name
        : null;

    final success = await _cartProvider.addToCart(
      product.productId,
      _quantity,
      selectedVariant: selectedVariant,
    );

    if (!mounted) return;

    setState(() => _isAddingToCart = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $_quantity sản phẩm ${selectedVariant != null ? '($selectedVariant) ' : ''}vào giỏ hàng!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cartProvider.errorMessage ??
                'Không thể thêm sản phẩm vào giỏ hàng',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return provider.ChangeNotifierProvider.value(
      value: _cartProvider,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
        body: productAsync.when(
          data: (product) => _buildDetailContent(product, isDark),
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          error: (err, stack) {
            final fallbackProduct = _getFallbackProduct();
            return _buildDetailContent(fallbackProduct, isDark);
          },
        ),
        bottomNavigationBar: _buildBottomCartBar(isDark),
      ),
    );
  }

  Widget _buildDetailContent(Product product, bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Image Header SliverAppBar
        _buildSliverAppBar(product, isDark),

        // Product Details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info block (Title, ratings, pricing)
                _buildInfoBlock(product, isDark),
                const SizedBox(height: AppSpacing.l),

                // Highlights Row
                _buildNutritionHighlightsRow(isDark),
                const SizedBox(height: AppSpacing.xl),

                // Variant Selection
                _buildVariantSelection(product, isDark),
                const SizedBox(height: AppSpacing.xl),

                // Description
                _buildDescription(product, isDark),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Product product, bool isDark) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.85),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            child: IconButton(
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite ? Colors.redAccent : Colors.black87,
                size: 22,
              ),
              onPressed: _onFavoriteToggle,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product-image-${product.productId}',
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: product.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, err) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.pets_rounded,
                    size: 72,
                    color: AppColors.primary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoBlock(Product product, bool isDark) {
    final hasVariants = product.variants != null && product.variants!.isNotEmpty;
    final price = hasVariants && _selectedVariantIndex < product.variants!.length
        ? product.variants![_selectedVariantIndex].price
        : product.price;
    final stock = hasVariants && _selectedVariantIndex < product.variants!.length
        ? product.variants![_selectedVariantIndex].stock
        : product.stock;
    final variantName = hasVariants && _selectedVariantIndex < product.variants!.length
        ? product.variants![_selectedVariantIndex].name
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey[100]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and category
          Text(
            product.name,
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.category?.name ?? 'Bán chạy',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (stock <= 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'HẾT HÀNG',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          const Divider(),
          const SizedBox(height: AppSpacing.m),

          // Rating and Sold
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '4.8',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(142 đánh giá)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                stock > 0
                    ? 'Còn $stock sản phẩm'
                    : 'Hết hàng',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Price Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(price),
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                variantName != null ? '/ $variantName' : '/ ${product.unit}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionHighlightsRow(bool isDark) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _nutritionHighlights.length,
        itemBuilder: (context, index) {
          final highlight = _nutritionHighlights[index];
          final highlightColor = highlight['color'] as Color;
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey[100]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    highlight['icon'] as IconData,
                    color: highlightColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight['label'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        highlight['desc'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVariantSelection(Product product, bool isDark) {
    final hasVariants = product.variants != null && product.variants!.isNotEmpty;
    if (!hasVariants) return const SizedBox.shrink();

    final variants = product.variants!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn ${product.variantLabel ?? 'phân loại'}',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: List.generate(variants.length, (index) {
            final variant = variants[index];
            final isSelected = _selectedVariantIndex == index;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedVariantIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : Colors.grey[300]!),
                  ),
                ),
                child: Text(
                  variant.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDescription(Product product, bool isDark) {
    final desc = product.description ?? 'Không có mô tả cho sản phẩm này.';
    final isLongText = desc.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết sản phẩm',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isLongText && !_isDescriptionExpanded
              ? '${desc.substring(0, 150)}...'
              : desc,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        if (isLongText)
          TextButton(
            onPressed: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomCartBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity Picker
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 20),
                    onPressed: _quantity > 1
                        ? () {
                            setState(() {
                              _quantity--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    '$_quantity',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.l),

            // Add to Cart Button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9E66), Color(0xFFFF8C42)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isAddingToCart
                      ? null
                      : () async {
                          final product = await ref.read(
                            productDetailProvider(widget.productId).future,
                          );
                          if (!mounted) return;
                          await _addToCart(product);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Thêm vào giỏ hàng',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
