import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/home_provider.dart';
import '../../../core/constants/app_colors.dart';

class CategoryGridWidget extends ConsumerWidget {
  const CategoryGridWidget({super.key});
  Widget _buildCategoryImage(String categoryName) {
  // Ánh xạ tên danh mục với file ảnh cụ thể
  // Đảm bảo các file này tồn tại trong public/images/
  final String imageName = switch (categoryName.toLowerCase()) {
    'thức ăn' => 'pets_icon.png',
    'bánh thưởng' => 'pets_icon.png',
    'phụ kiện' => 'pets_icon.png',
    'chăm sóc' => 'pets_icon.png',
    'vệ sinh' => 'pets_icon.png',
    'đồ chơi' => 'pets_icon.png',
    _ => 'pets_icon.png',
  };

  return Image.asset(
    'public/images/$imageName',
    width: 28,
    height: 28,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => const Icon(
      Icons.pets_rounded,
      color: AppColors.primary,
      size: 20,
    ),
  );
} 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh mục nổi bật',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2F2F2F),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/search'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) return const SizedBox.shrink();
            // Use 180dp height to accommodate 2 rows of items cleanly
            return SizedBox(
              height: 190,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 horizontal rows
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95, // Adjust aspect ratio for horizontal list spacing
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return InkWell(
                    onTap: () => context.push(
                      '/category/${category.categoryId}?name=${Uri.encodeComponent(category.name)}',
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.primary.withOpacity(0.15) 
                                : AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: ClipOval(
  child: _buildCategoryImage(category.name),
),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 220,
                          child: Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[300] : const Color(0xFF4F4F4F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 190,
            child: Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                itemCount: 8,
                itemBuilder: (context, index) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 50,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
