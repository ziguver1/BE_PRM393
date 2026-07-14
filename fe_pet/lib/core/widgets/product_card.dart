import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/product.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;

  String _formatCurrency(double value) {
    final raw = value.toStringAsFixed(0);
    final chars = raw.split('');
    for (var i = chars.length - 3; i > 0; i -= 3) {
      chars.insert(i, '.');
    }
    return '${chars.join()}đ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simulate discount on even IDs for realistic catalog feel
    final hasDiscount = widget.product.productId % 2 == 0;
    final discountPercent = 20;
    final oldPrice = widget.product.price / 0.8;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image (Deterministic aspect ratio for Masonry grid compatibility)
              AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[900]
                            : const Color(0xFFF6F6F6),
                      ),
                      child:
                          widget.product.imageUrl != null &&
                              widget.product.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.product.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (c, u) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (c, u, e) => const Icon(
                                Icons.broken_image_rounded,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.pets_rounded,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),

                    // Discount Badge
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Favorite Button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFavorite = !_isFavorite;
                            });
                          },
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavorite
                                ? AppColors.error
                                : AppColors.textPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info (Laid out naturally to support unbounded parent constraints)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.category?.name ?? 'PETS',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
 
                    // Rating & Sales Row
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '4.8',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Đã bán ${(widget.product.productId * 19) % 150 + 12}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
 
                    // Pricing & Buy button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasDiscount)
                                Text(
                                  _formatCurrency(oldPrice),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                _formatCurrency(widget.product.price),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Small Cart Action Circle
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
