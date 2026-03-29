import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/bmi_calculator.dart';
import '../../../core/utils/bmr_calculator.dart';
import '../../../core/utils/tdee_calculator.dart';
import '../../../core/utils/calorie_goal_calculator.dart';

/// Edit Profile Screen
/// 
/// Allows users to edit their personal information:
/// - Name
/// - Age
/// - Gender
/// - Height
/// - Weight
/// - Goal type
/// - Target weight
/// - Activity level
/// 
/// Automatically recalculates BMI, BMR, TDEE, and calorie goal
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;

  // Dropdown values
  late String _gender;
  late String _goalType;
  late String _activityLevel;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  /// Initialize form controllers with existing data
  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.userProfile['name'] as String,
    );
    _ageController = TextEditingController(
      text: (widget.userProfile['age'] as int).toString(),
    );
    _heightController = TextEditingController(
      text: (widget.userProfile['height_cm'] as num).toStringAsFixed(0),
    );
    _weightController = TextEditingController(
      text: (widget.userProfile['weight_kg'] as num).toStringAsFixed(1),
    );
    _targetWeightController = TextEditingController(
      text: (widget.userProfile['target_weight_kg'] as num).toStringAsFixed(1),
    );

    _gender = widget.userProfile['gender'] as String;
    _goalType = widget.userProfile['goal_type'] as String;
    _activityLevel = widget.userProfile['activity_level'] as String;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  /// Save profile changes
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Parse values
      final age = int.parse(_ageController.text);
      final heightCm = double.parse(_heightController.text);
      final weightKg = double.parse(_weightController.text);
      final targetWeightKg = double.parse(_targetWeightController.text);

      // Calculate new metrics
      final bmi = BMICalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
      );
      final bmr = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        isMale: _gender.toLowerCase() == 'male',
      );
      final activityFactor = TDEECalculator.getActivityFactor(_activityLevel);
      final tdee = TDEECalculator.calculate(
        bmr: bmr,
        activityFactor: activityFactor,
      );
      
      // Calculate weekly goal for calorie calculation
      final weeklyGoalKg = (targetWeightKg - weightKg).abs() / 52; // Assume 1 year plan
      final calorieGoal = CalorieGoalCalculator.calculate(
        tdee: tdee,
        goalType: _goalType,
        weeklyGoalKg: weeklyGoalKg.clamp(0.25, 1.0), // Safe range: 0.25-1 kg/week
      );

      // Update user profile
      final updatedProfile = {
        ...widget.userProfile,
        'name': _nameController.text.trim(),
        'age': age,
        'gender': _gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'target_weight_kg': targetWeightKg,
        'goal_type': _goalType,
        'activity_level': _activityLevel,
        'bmi': bmi,
        'bmr': bmr,
        'tdee': tdee,
        'calorie_goal': calorieGoal,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Get user ID (assuming first user, ID = 1)
      final userId = widget.userProfile['id'] as int? ?? 1;
      await DatabaseHelper.instance.updateUser(userId, updatedProfile);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Đã cập nhật hồ sơ thành công',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );

        // Return to profile screen with success flag
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.marginLarge),
          children: [
            _buildSection(
              'Thông tin cá nhân',
              [
                _buildTextField(
                  controller: _nameController,
                  label: 'Tên',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.marginMedium),
                _buildTextField(
                  controller: _ageController,
                  label: 'Tuổi',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tuổi';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 10 || age > 120) {
                      return 'Tuổi không hợp lệ (10-120)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.marginMedium),
                _buildGenderDropdown(),
              ],
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            
            _buildSection(
              'Chỉ số cơ thể',
              [
                _buildTextField(
                  controller: _heightController,
                  label: 'Chiều cao (cm)',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập chiều cao';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height < 100 || height > 250) {
                      return 'Chiều cao không hợp lệ (100-250cm)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.marginMedium),
                _buildTextField(
                  controller: _weightController,
                  label: 'Cân nặng (kg)',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập cân nặng';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight < 20 || weight > 300) {
                      return 'Cân nặng không hợp lệ (20-300kg)';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            
            _buildSection(
              'Mục tiêu',
              [
                _buildGoalTypeDropdown(),
                const SizedBox(height: AppDimensions.marginMedium),
                _buildTextField(
                  controller: _targetWeightController,
                  label: 'Cân nặng mục tiêu (kg)',
                  icon: Icons.gps_fixed,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập cân nặng mục tiêu';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight < 20 || weight > 300) {
                      return 'Cân nặng không hợp lệ (20-300kg)';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            
            _buildSection(
              'Mức độ hoạt động',
              [
                _buildActivityLevelDropdown(),
              ],
            ),
            const SizedBox(height: AppDimensions.marginLarge * 2),
          ],
        ),
      ),
    );
  }

  /// Build section with title and children
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppDimensions.marginMedium),
        Container(
          padding: const EdgeInsets.all(AppDimensions.marginLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  /// Build text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  /// Build gender dropdown
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      decoration: InputDecoration(
        labelText: 'Giới tính',
        prefixIcon: Icon(Icons.wc, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Nam')),
        DropdownMenuItem(value: 'female', child: Text('Nữ')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _gender = value);
        }
      },
    );
  }

  /// Build goal type dropdown
  Widget _buildGoalTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _goalType,
      decoration: InputDecoration(
        labelText: 'Loại mục tiêu',
        prefixIcon: Icon(Icons.flag, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'lose', child: Text('Giảm cân')),
        DropdownMenuItem(value: 'maintain', child: Text('Duy trì cân nặng')),
        DropdownMenuItem(value: 'gain', child: Text('Tăng cân')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _goalType = value);
        }
      },
    );
  }

  /// Build activity level dropdown
  Widget _buildActivityLevelDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _activityLevel,
      isExpanded: true, // Fix text overflow
      decoration: InputDecoration(
        labelText: 'Mức độ hoạt động',
        prefixIcon: Icon(Icons.directions_run, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'sedentary',
          child: Text(
            'Ít vận động (Ít hoặc không tập)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'light',
          child: Text(
            'Vận động nhẹ (1-3 ngày/tuần)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'moderate',
          child: Text(
            'Vận động trung bình (3-5 ngày/tuần)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'active',
          child: Text(
            'Vận động nhiều (6-7 ngày/tuần)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'very_active',
          child: Text(
            'Vận động rất nhiều (Vận động viên)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _activityLevel = value);
        }
      },
    );
  }
}

