import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/tdee_calculator.dart';

/// Activity Level Step
class ActivityLevelStep extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onNext;

  const ActivityLevelStep({
    super.key,
    required this.userData,
    required this.onNext,
  });

  @override
  State<ActivityLevelStep> createState() => _ActivityLevelStepState();
}

class _ActivityLevelStepState extends State<ActivityLevelStep> {
  late String _selectedLevel;

  final List<ActivityLevelOption> _options = [
    ActivityLevelOption(
      value: 'sedentary',
      name: AppStrings.sedentary,
      description: AppStrings.sedentaryDesc,
      icon: Icons.weekend,
      factor: TDEECalculator.sedentary,
    ),
    ActivityLevelOption(
      value: 'light',
      name: AppStrings.light,
      description: AppStrings.lightDesc,
      icon: Icons.directions_walk,
      factor: TDEECalculator.lightlyActive,
    ),
    ActivityLevelOption(
      value: 'moderate',
      name: AppStrings.moderate,
      description: AppStrings.moderateDesc,
      icon: Icons.directions_run,
      factor: TDEECalculator.moderatelyActive,
    ),
    ActivityLevelOption(
      value: 'active',
      name: AppStrings.active,
      description: AppStrings.activeDesc,
      icon: Icons.fitness_center,
      factor: TDEECalculator.veryActive,
    ),
    ActivityLevelOption(
      value: 'extra_active',
      name: AppStrings.veryActive,
      description: AppStrings.veryActiveDesc,
      icon: Icons.sports_gymnastics,
      factor: TDEECalculator.extraActive,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.userData['activityLevel'] ?? 'moderate';
  }

  void _handleNext() {
    widget.onNext({
      'activityLevel': _selectedLevel,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppStrings.selectActivityLevel,
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Chọn mức độ hoạt động hàng ngày của bạn',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXL),

          // Activity level options
          ...List.generate(_options.length, (index) {
            final option = _options[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _options.length - 1
                    ? AppDimensions.spaceM
                    : 0,
              ),
              child: _buildActivityCard(option),
            );
          }),

          const SizedBox(height: AppDimensions.spaceXL),

          // Next button
          CustomButton(
            text: AppStrings.next,
            onPressed: _handleNext,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityLevelOption option) {
    final isSelected = _selectedLevel == option.value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedLevel = option.value;
        });
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                option.icon,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: AppTextStyles.subtitle1.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hệ số: ${option.factor}x',
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Activity Level Option Model
class ActivityLevelOption {
  final String value;
  final String name;
  final String description;
  final IconData icon;
  final double factor;

  ActivityLevelOption({
    required this.value,
    required this.name,
    required this.description,
    required this.icon,
    required this.factor,
  });
}

