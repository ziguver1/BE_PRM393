import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class QuickServiceList extends StatelessWidget {
  const QuickServiceList({super.key});

  static final List<Map<String, dynamic>> _services = [
    {
      'label': 'Giao hàng',
      'icon': Icons.local_shipping_rounded,
      'color': Colors.blue,
      'desc': 'Siêu tốc 2h',
    },
    {
      'label': 'Bác sĩ thú y',
      'icon': Icons.medical_services_rounded,
      'color': Colors.red,
      'desc': 'Tư vấn 24/7',
    },
    {
      'label': 'Spa & Grooming',
      'icon': Icons.spa_rounded,
      'color': Colors.green,
      'desc': 'Tắm, tỉa lông',
    },
    {
      'label': 'Huấn luyện',
      'icon': Icons.pets_rounded,
      'color': Colors.orange,
      'desc': 'Nghe lời ngay',
    },
    {
      'label': 'Bảo hiểm',
      'icon': Icons.shield_rounded,
      'color': Colors.purple,
      'desc': 'An tâm 100%',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dịch vụ nhanh',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              final serviceColor = service['color'] as Color;
              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: serviceColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        service['icon'] as IconData,
                        color: serviceColor,
                        size: 20,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['label'] as String,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          service['desc'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
