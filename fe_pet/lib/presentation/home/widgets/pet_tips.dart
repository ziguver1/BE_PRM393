import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class PetTips extends StatefulWidget {
  const PetTips({super.key});

  @override
  State<PetTips> createState() => _PetTipsState();
}

class _PetTipsState extends State<PetTips> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _tips = const [
    {
      'title': '5 bước chăm sóc lông cho cún cưng luôn bóng mượt',
      'image': 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=500&auto=format&fit=crop&q=60',
      'readTime': '4 phút đọc',
      'content': 'Chăm sóc lông cho chó không chỉ giúp chúng trông đẹp hơn mà còn bảo vệ sức khỏe da. Hãy bắt đầu bằng việc chải lông hàng ngày bằng lược chuyên dụng. Tiếp theo, tắm cho chó 1-2 lần/tháng bằng sữa tắm phù hợp. Bổ sung omega-3 và omega-6 vào khẩu phần ăn cũng giúp lông thêm bóng mượt. Đừng quên kiểm tra ve rận thường xuyên nhé!',
    },
    {
      'title': 'Chế độ dinh dưỡng hoàn hảo cho mèo con dưới 1 tuổi',
      'image': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=500&auto=format&fit=crop&q=60',
      'readTime': '5 phút đọc',
      'content': 'Mèo con dưới 1 tuổi cần lượng protein và calo rất cao để phát triển xương và cơ bắp. Hãy chọn loại hạt dành riêng cho mèo con (kitten) có chứa DHA giúp phát triển trí não. Chia nhỏ bữa ăn thành 3-4 cữ mỗi ngày và luôn đảm bảo có sẵn nước sạch. Hạn chế cho mèo con uống sữa bò vì dễ gây tiêu chảy.',
    },
    {
      'title': 'Làm thế nào để huấn luyện cún đi vệ sinh đúng chỗ',
      'image': 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=500&auto=format&fit=crop&q=60',
      'readTime': '6 phút đọc',
      'content': 'Huấn luyện đi vệ sinh đòi hỏi sự kiên nhẫn. Hãy bắt đầu bằng việc thiết lập một khu vực vệ sinh cố định bằng khay hoặc tã lót. Đưa cún ra khu vực đó ngay sau khi ăn, ngủ dậy hoặc chơi đùa. Khen ngợi và thưởng ngay lập tức khi cún làm đúng chỗ. Tuyệt đối không quát mắng khi cún làm sai vì sẽ gây sợ hãi.',
    },
    {
      'title': 'Dấu hiệu nhận biết thú cưng đang bị stress',
      'image': 'https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=500&auto=format&fit=crop&q=60',
      'readTime': '3 phút đọc',
      'content': 'Thú cưng cũng có thể bị stress do môi trường sống thay đổi hoặc thiếu sự quan tâm. Các dấu hiệu bao gồm: liếm lông quá mức đến rụng lông, biếng ăn, trốn vào góc tối, sủa hoặc kêu rên liên tục, đi vệ sinh bậy. Hãy dành thời gian chơi đùa, tạo không gian an toàn và cân nhắc sử dụng pheromone an thần nếu cần.',
    },
    {
      'title': 'Cách chọn đồ chơi an toàn, phù hợp cho thú cưng',
      'image': 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=500&auto=format&fit=crop&q=60',
      'readTime': '4 phút đọc',
      'content': 'Đồ chơi giúp thú cưng giải tỏa năng lượng và kích thích trí não. Hãy chọn đồ chơi có kích thước phù hợp, không quá nhỏ để tránh nuốt phải. Tránh các loại đồ chơi có chi tiết dễ đứt gãy hoặc sơn độc hại. Đồ chơi cao su đặc hoặc dây thừng đan chặt là lựa chọn tuyệt vời cho chó thích nhai, trong khi cần câu mèo lại hấp dẫn các bé mèo.',
    },
  ];

  void _showTipDetail(Map<String, String> tip) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: tip['image']!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title']!,
                        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            tip['readTime']!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tip['content'] ?? 'Nội dung đang được cập nhật...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Kinh nghiệm & Mẹo hay',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tips.length,
                itemBuilder: (context, index) {
                  final tip = _tips[index];
                  return GestureDetector(
                    onTap: () => _showTipDetail(tip),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl: tip['image']!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tip['title']!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tip['readTime']!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, size: 24, color: AppColors.textPrimary),
                    onPressed: _scrollLeft,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 24, color: AppColors.textPrimary),
                    onPressed: _scrollRight,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
