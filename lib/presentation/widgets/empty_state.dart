// Empty State Widget
// 
// Beautiful empty states with illustrations for better UX
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

/// Empty state widget with icon and message
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLarge * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 64,
                      color: iconColor ?? AppColors.primary,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: AppDimensions.paddingLarge),

            // Title
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.paddingSmall),

            // Message
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppDimensions.paddingLarge),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLarge,
                    vertical: AppDimensions.paddingMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for no meals
class NoMealsEmptyState extends StatelessWidget {
  final VoidCallback? onAddMeal;

  const NoMealsEmptyState({
    super.key,
    this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.restaurant_menu,
      title: 'Chưa có bữa ăn nào',
      message: 'Bắt đầu ghi lại bữa ăn của bạn\nđể theo dõi dinh dưỡng',
      actionLabel: 'Thêm bữa ăn',
      onAction: onAddMeal,
    );
  }
}

/// Empty state for search results
class NoSearchResultsEmptyState extends StatelessWidget {
  final String searchQuery;

  const NoSearchResultsEmptyState({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Không tìm thấy kết quả',
      message: 'Không có kết quả nào cho "$searchQuery"\nThử tìm kiếm với từ khóa khác',
      iconColor: AppColors.error,
    );
  }
}

/// Empty state for history
class NoHistoryEmptyState extends StatelessWidget {
  const NoHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.history,
      title: 'Chưa có lịch sử',
      message: 'Lịch sử bữa ăn của bạn\nsẽ xuất hiện ở đây',
    );
  }
}

/// Empty state for water tracking
class NoWaterEmptyState extends StatelessWidget {
  final VoidCallback? onAddWater;

  const NoWaterEmptyState({
    super.key,
    this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.water_drop_outlined,
      title: 'Chưa uống nước hôm nay',
      message: 'Bắt đầu theo dõi lượng nước\nđể đảm bảo cơ thể được hydrat hóa',
      actionLabel: 'Thêm nước',
      onAction: onAddWater,
      iconColor: Colors.blue,
    );
  }
}

/// Empty state for weight tracking
class NoWeightEmptyState extends StatelessWidget {
  final VoidCallback? onAddWeight;

  const NoWeightEmptyState({
    super.key,
    this.onAddWeight,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.monitor_weight_outlined,
      title: 'Chưa có dữ liệu cân nặng',
      message: 'Bắt đầu ghi lại cân nặng\nđể theo dõi tiến độ',
      actionLabel: 'Ghi cân nặng',
      onAction: onAddWeight,
      iconColor: Colors.purple,
    );
  }
}

