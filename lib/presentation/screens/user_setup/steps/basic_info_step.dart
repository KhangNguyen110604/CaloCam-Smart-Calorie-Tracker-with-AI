import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';

/// Basic Info Step - Collect gender, age, height, weight
/// (Name is collected during registration)
class BasicInfoStep extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onNext;

  const BasicInfoStep({
    super.key,
    required this.userData,
    required this.onNext,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedGender;
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.userData['gender'] ?? 'male';
    _ageController.text = (widget.userData['age'] ?? 25).toString();
    _heightController.text = (widget.userData['height'] ?? 170.0).toStringAsFixed(1);
    _weightController.text = (widget.userData['weight'] ?? 70.0).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final age = int.tryParse(_ageController.text) ?? 25;
    final height = double.tryParse(_heightController.text) ?? 170.0;
    final weight = double.tryParse(_weightController.text) ?? 70.0;

    widget.onNext({
      'gender': _selectedGender,
      'age': age,
      'height': height,
      'weight': weight,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Thông tin cơ bản',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Nhập thông tin cơ bản của bạn',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Gender Selection
            Text(
              'Giới tính',
              style: AppTextStyles.subtitle1,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Row(
              children: [
                Expanded(
                  child: _buildGenderCard(
                    'male',
                    'Nam',
                    Icons.male,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: _buildGenderCard(
                    'female',
                    'Nữ',
                    Icons.female,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Age Input
            _buildInputField(
              label: 'Tuổi',
              controller: _ageController,
              icon: Icons.cake_outlined,
              iconColor: AppColors.primary,
              suffix: 'tuổi',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tuổi';
                }
                final age = int.tryParse(value);
                if (age == null) {
                  return 'Tuổi phải là số';
                }
                if (age < 15 || age > 80) {
                  return 'Tuổi phải từ 15-80';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Height Input
            _buildInputField(
              label: 'Chiều cao',
              controller: _heightController,
              icon: Icons.height_outlined,
              iconColor: AppColors.secondary,
              suffix: 'cm',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập chiều cao';
                }
                final height = double.tryParse(value);
                if (height == null) {
                  return 'Chiều cao phải là số';
                }
                if (height < 120 || height > 220) {
                  return 'Chiều cao phải từ 120-220 cm';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Weight Input
            _buildInputField(
              label: 'Cân nặng hiện tại',
              controller: _weightController,
              icon: Icons.monitor_weight_outlined,
              iconColor: AppColors.accent,
              suffix: 'kg',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập cân nặng';
                }
                final weight = double.tryParse(value);
                if (weight == null) {
                  return 'Cân nặng phải là số';
                }
                if (weight < 30 || weight > 200) {
                  return 'Cân nặng phải từ 30-200 kg';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spaceXXL),

            // Next button
            CustomButton(
              text: 'Tiếp theo',
              onPressed: _handleNext,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String suffix,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.subtitle1,
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusM),
                    bottomLeft: Radius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              // Input
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: AppDimensions.paddingM,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                  ],
                  validator: validator,
                ),
              ),
              // Suffix
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.paddingM),
                child: Text(
                  suffix,
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              label,
              style: AppTextStyles.subtitle2.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: AppDimensions.spaceS),
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

