import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/calorie_goal_calculator.dart';

/// Target Weight Step - Set target weight and weekly goal
class TargetWeightStep extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onNext;

  const TargetWeightStep({
    super.key,
    required this.userData,
    required this.onNext,
  });

  @override
  State<TargetWeightStep> createState() => _TargetWeightStepState();
}

class _TargetWeightStepState extends State<TargetWeightStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _targetWeightController;
  late double _weeklyGoal;
  int? _estimatedWeeks;

  @override
  void initState() {
    super.initState();
    _targetWeightController = TextEditingController(
      text: widget.userData['targetWeight']?.toString() ?? '',
    );
    _weeklyGoal = widget.userData['weeklyGoal'] ?? 0.5;
    _calculateEstimatedTime();
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  void _calculateEstimatedTime() {
    if (_targetWeightController.text.isEmpty) return;

    final currentWeight = widget.userData['weight'] as double;
    final targetWeight = double.tryParse(_targetWeightController.text);

    if (targetWeight == null) return;

    setState(() {
      _estimatedWeeks = CalorieGoalCalculator.calculateTimeToGoal(
        currentWeight: currentWeight,
        targetWeight: targetWeight,
        weeklyGoalKg: _weeklyGoal,
      );
    });
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      widget.onNext({
        'targetWeight': double.parse(_targetWeightController.text),
        'weeklyGoal': _weeklyGoal,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalType = widget.userData['goalType'] as String;
    final currentWeight = widget.userData['weight'] as double;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              AppStrings.weightGoal,
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Đặt mục tiêu cân nặng và tốc độ',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Current weight info
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.primaryVeryLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.scale, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.spaceM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cân nặng hiện tại',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        '$currentWeight kg',
                        style: AppTextStyles.h6.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // Target weight
            CustomNumberField(
              label: AppStrings.targetWeight,
              hint: goalType == 'lose' ? '65' : '75',
              controller: _targetWeightController,
              validator: (value) {
                final error = Validators.weight(value);
                if (error != null) return error;

                final target = double.tryParse(value!);
                if (target == null) return null;

                if (goalType == 'lose' && target >= currentWeight) {
                  return 'Cân nặng mục tiêu phải nhỏ hơn cân nặng hiện tại';
                }
                if (goalType == 'gain' && target <= currentWeight) {
                  return 'Cân nặng mục tiêu phải lớn hơn cân nặng hiện tại';
                }

                return null;
              },
              suffix: AppStrings.weightUnit,
              allowDecimal: true,
              onChanged: (_) => _calculateEstimatedTime(),
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // Weekly goal
            Text(
              AppStrings.weeklyGoal,
              style: AppTextStyles.subtitle2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Tốc độ ${goalType == 'lose' ? 'giảm' : 'tăng'} cân an toàn: 0.25-1.0 kg/tuần',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),

            // Weekly goal slider
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_weeklyGoal kg${AppStrings.perWeek}',
                        style: AppTextStyles.h6.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      if (!CalorieGoalCalculator.isWeeklyGoalSafe(
                          goalType, _weeklyGoal))
                        const Icon(
                          Icons.warning_amber,
                          color: AppColors.warning,
                          size: 20,
                        ),
                    ],
                  ),
                  Slider(
                    value: _weeklyGoal,
                    min: 0.25,
                    max: 1.0,
                    divisions: 3,
                    label: '$_weeklyGoal kg',
                    onChanged: (value) {
                      setState(() {
                        _weeklyGoal = value;
                      });
                      _calculateEstimatedTime();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.25 kg', style: AppTextStyles.caption),
                      Text('1.0 kg', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),

            // Warning if unsafe
            if (!CalorieGoalCalculator.isWeeklyGoalSafe(goalType, _weeklyGoal))
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.spaceM),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: AppColors.warning),
                      const SizedBox(width: AppDimensions.spaceS),
                      Expanded(
                        child: Text(
                          CalorieGoalCalculator.getWeeklyGoalWarning(
                                  goalType, _weeklyGoal) ??
                              '',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Estimated time
            if (_estimatedWeeks != null) ...[
              const SizedBox(height: AppDimensions.spaceL),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.accent),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thời gian dự kiến',
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            '$_estimatedWeeks tuần (${(_estimatedWeeks! / 4).ceil()} tháng)',
                            style: AppTextStyles.subtitle1.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimensions.spaceXL),

            // Next button
            CustomButton(
              text: AppStrings.next,
              onPressed: _handleNext,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}

