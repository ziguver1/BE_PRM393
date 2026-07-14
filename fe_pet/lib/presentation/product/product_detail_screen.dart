import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductService _productService;
  int _quantity = 1;
  int _selectedVariantIndex = 0;
  bool _isAddingToCart = false;
  bool _isFavorite = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
  }

  String _formatCurrency(double value) {
    final raw = value.toStringAsFixed(0);
    final chars = raw.split('');
    for (var i = chars.length - 3; i > 0; i -= 3) {
      chars.insert(i, '.');
    }
    return '${chars.join()}đ';
  }

  void _onFavoriteToggle() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? 'Đã thêm vào danh sách yêu thích!'
              : 'Đã xoá khỏi danh sách yêu thích!',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

Future<bool> _addToCart(ProductModel product) async {
    if (_isAddingToCart) return false;

    setState(() => _isAddingToCart = true);

    try {
      final cartProvider = context.read<CartProvider>();
      final hasVariants =
          product.productVariants != null && product.productVariants!.isNotEmpty;
      final selectedVariant =
          hasVariants && _selectedVariantIndex < product.productVariants!.length
              ? product.productVariants![_selectedVariantIndex].name
              : null;

      final success = await cartProvider.addToCart(
        product.productId,
        _quantity,
        selectedVariant: selectedVariant,
      );

      // Phải kiểm tra mounted trước khi gọi setState hoặc context
      if (!mounted) return false;

      setState(() => _isAddingToCart = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm $_quantity sản phẩm ${selectedVariant != null ? '($selectedVariant) ' : ''}vào giỏ hàng!',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1), // Rút ngắn thời gian hiện thông báo
          ),
        );
        return true; // Trả về true báo hiệu đã thêm thành công
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cartProvider.errorMessage ?? 'Không thể thêm sản phẩm vào giỏ hàng',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      setState(() => _isAddingToCart = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  Future<void> _buyNow(ProductModel product) async {
    // 1. Đợi hàm _addToCart chạy xong và lấy kết quả thành công/thất bại
    final success = await _addToCart(product);
    
    // 2. Chỉ chuyển hướng sang giỏ hàng nếu THÊM THÀNH CÔNG và màn hình vẫn đang hiển thị (mounted)
    if (success && mounted) {
      // SỬA push THÀNH go Ở ĐÂY 👇
      context.go('/cart');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with Image Carousel
          _buildSliverAppBar(product, isDark),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Block
                  _buildInfoBlock(product, isDark),
                  const SizedBox(height: AppSpacing.l),

                  // Variant Selection
                  if (product.productVariants != null &&
                      product.productVariants!.isNotEmpty)
                    _buildVariantSelection(product, isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Filters / Tags
                  if (product.productFilters != null &&
                      product.productFilters!.isNotEmpty)
                    _buildFilterTags(product, isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Description
                  _buildDescriptionSection(product, isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Product Attributes
                  _buildAttributesSection(product, isDark),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCartBar(product, isDark),
    );
  }

  Widget _buildSliverAppBar(ProductModel product, bool isDark) {
    final imageUrls = product.getAllImageUrls();

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surface,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
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
          padding: const EdgeInsets.only(right: 8),
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
        background: Stack(
          children: [
            // Image Carousel
            CarouselSlider(
              options: CarouselOptions(
                height: double.infinity,
                enlargeCenterPage: false,
                enableInfiniteScroll: imageUrls.length > 1,
                onPageChanged: (index, reason) {
                  setState(() => _currentImageIndex = index);
                },
              ),
              items: imageUrls.isEmpty
                  ? [
                      Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ]
                  : imageUrls.map((imageUrl) {
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
            ),

            // Image Counter
            if (imageUrls.length > 1)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(ProductModel product, bool isDark) {
    final hasVariants = product.productVariants != null &&
        product.productVariants!.isNotEmpty;
    final displayPrice = hasVariants && _selectedVariantIndex < product.productVariants!.length
        ? product.productVariants![_selectedVariantIndex].price
        : product.price;
    final displayStock = hasVariants && _selectedVariantIndex < product.productVariants!.length
        ? product.productVariants![_selectedVariantIndex].stock
        : product.stock;

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
          // Product Name
          Text(
            product.name,
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Category Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.category?.name ?? 'Sản phẩm',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (displayStock <= 0)
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

          // Rating and Stock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                ],
              ),
              Text(
                displayStock > 0
                    ? 'Còn $displayStock'
                    : 'Hết hàng',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: displayStock > 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(displayPrice),
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/${product.unit}',
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

  Widget _buildVariantSelection(ProductModel product, bool isDark) {
    final variants = product.productVariants!;
    if (variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn phân loại',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(variants.length, (index) {
            final variant = variants[index];
            final isSelected = _selectedVariantIndex == index;

            return Material(
              child: InkWell(
                onTap: () {
                  setState(() => _selectedVariantIndex = index);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.borderDark
                              : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    variant.name ?? 'Biến thể',
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
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterTags(ProductModel product, bool isDark) {
    final filtersByGroup = product.getFiltersByGroup();
    if (filtersByGroup.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filtersByGroup.entries.map((entry) {
        final groupName = entry.key;
        final filters = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filters.map((filter) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    filter.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionSection(ProductModel product, bool isDark) {
    final description = product.description ??
        'Không có mô tả chi tiết cho sản phẩm này.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả sản phẩm',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey[100]!,
            ),
          ),
          child: Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesSection(ProductModel product, bool isDark) {
    // Placeholder for product attributes
    // You can extend this to show actual attributes from backend
    return const SizedBox.shrink();
  }

Widget _buildBottomCartBar(ProductModel product, bool isDark) {
    // ĐÃ THÊM COLUMN Ở ĐÂY ĐỂ KHÓA CHIỀU CAO
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
            top: false,
            child: Row(
              children: [
                // Quantity Picker
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 20),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      SizedBox(
                        width: 30,
                        // ĐÃ BỎ CENTER VÀ DÙNG TEXTALIGN Ở ĐÂY
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.l),

                // Add to Cart Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isAddingToCart
                        ? null
                        : () => _addToCart(product),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Thêm vào giỏ',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),

                // Buy Now Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9E66), Color(0xFFFF8C42)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _isAddingToCart
                          ? null
                          : () => _buyNow(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Mua ngay',
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
        ),
      ],
    );
  }
}
