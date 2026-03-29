import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/calorie_goal_calculator.dart';

/// Goal Selection Step - Lose/Maintain/Gain Weight
class GoalSelectionStep extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onNext;

  const GoalSelectionStep({
    super.key,
    required this.userData,
    required this.onNext,
  });

  @override
  State<GoalSelectionStep> createState() => _GoalSelectionStepState();
}

class _GoalSelectionStepState extends State<GoalSelectionStep> {
  late String _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.userData['goalType'] ?? 'maintain';
  }

  void _handleNext() {
    widget.onNext({
      'goalType': _selectedGoal,
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
            AppStrings.selectGoal,
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Chọn mục tiêu phù hợp với bạn',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXL),

          // Goal cards
          _buildGoalCard(
            'lose',
            AppStrings.loseWeight,
            AppStrings.loseWeightDesc,
            Icons.trending_down,
            AppColors.goalLoseWeight,
            'Giảm 0.25-1.0 kg/tuần',
          ),
          const SizedBox(height: AppDimensions.spaceM),

          _buildGoalCard(
            'maintain',
            AppStrings.maintainWeight,
            AppStrings.maintainWeightDesc,
            Icons.balance,
            AppColors.goalMaintain,
            'Duy trì cân nặng hiện tại',
          ),
          const SizedBox(height: AppDimensions.spaceM),

          _buildGoalCard(
            'gain',
            AppStrings.gainWeight,
            AppStrings.gainWeightDesc,
            Icons.trending_up,
            AppColors.goalGainWeight,
            'Tăng 0.25-1.0 kg/tuần',
          ),
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

  Widget _buildGoalCard(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final isSelected = _selectedGoal == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGoal = value;
        });
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        CalorieGoalCalculator.getGoalTypeIcon(value),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: AppTextStyles.h6.copyWith(
                          color: isSelected ? color : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? color : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

