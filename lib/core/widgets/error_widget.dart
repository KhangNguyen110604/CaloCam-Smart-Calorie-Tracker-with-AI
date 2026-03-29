import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import 'custom_button.dart';

/// Custom Error Widget
class CustomErrorWidget extends StatelessWidget {
  final String? message;
  final String? title;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const CustomErrorWidget({
    super.key,
    this.message,
    this.title,
    this.icon,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            if (title != null)
              Text(
                title!,
                style: AppTextStyles.h5.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null) const SizedBox(height: AppDimensions.spaceS),
            Text(
              message ?? 'Đã xảy ra lỗi. Vui lòng thử lại.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spaceL),
              CustomButton(
                text: retryButtonText ?? 'Thử lại',
                onPressed: onRetry,
                icon: Icons.refresh,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network Error Widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      icon: Icons.wifi_off,
      title: 'Không có kết nối',
      message: 'Vui lòng kiểm tra kết nối internet và thử lại.',
      onRetry: onRetry,
    );
  }
}

/// Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final String? message;
  final String? title;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionButtonText;

  const EmptyStateWidget({
    super.key,
    this.message,
    this.title,
    this.icon,
    this.onAction,
    this.actionButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            if (title != null)
              Text(
                title!,
                style: AppTextStyles.h5.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null) const SizedBox(height: AppDimensions.spaceS),
            Text(
              message ?? 'Không có dữ liệu',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: AppDimensions.spaceL),
              CustomButton(
                text: actionButtonText ?? 'Thêm mới',
                onPressed: onAction,
                icon: Icons.add,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No Meals Empty State
class NoMealsEmptyState extends StatelessWidget {
  final VoidCallback? onAddMeal;

  const NoMealsEmptyState({
    super.key,
    this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.restaurant_outlined,
      title: 'Chưa có bữa ăn',
      message: 'Thêm bữa ăn đầu tiên của bạn để bắt đầu theo dõi calo',
      onAction: onAddMeal,
      actionButtonText: 'Thêm bữa ăn',
    );
  }
}

/// No Search Results
class NoSearchResultsWidget extends StatelessWidget {
  final String? searchQuery;

  const NoSearchResultsWidget({
    super.key,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Không tìm thấy kết quả',
      message: searchQuery != null
          ? 'Không tìm thấy kết quả cho "$searchQuery"'
          : 'Không tìm thấy kết quả nào',
    );
  }
}

