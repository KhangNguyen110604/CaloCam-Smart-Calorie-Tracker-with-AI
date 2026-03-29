import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/utils/bmi_calculator.dart';
import '../../../../core/utils/bmr_calculator.dart';
import '../../../../core/utils/tdee_calculator.dart';
import '../../../../core/utils/calorie_goal_calculator.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/datasources/local/database_helper.dart';
import '../../../../data/datasources/local/shared_prefs_helper.dart';
import '../../main/main_navigation_screen.dart';

/// Summary Step - Calculate and save user data
class SummaryStep extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SummaryStep({
    super.key,
    required this.userData,
  });

  @override
  State<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<SummaryStep> {
  bool _isCalculating = true;
  bool _isSaving = false;
  late double _bmi;
  late double _bmr;
  late double _tdee;
  late double _calorieGoal;

  @override
  void initState() {
    super.initState();
    _calculateMetrics();
  }

  Future<void> _calculateMetrics() async {
    // Simulate calculation delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    final weight = widget.userData['weight'] as double;
    final height = widget.userData['height'] as double;
    final age = widget.userData['age'] as int;
    final isMale = widget.userData['gender'] == 'male';
    final activityLevel = widget.userData['activityLevel'] as String;
    final goalType = widget.userData['goalType'] as String;
    final weeklyGoal = widget.userData['weeklyGoal'] as double? ?? 0.5;

    // Calculate BMI
    _bmi = BMICalculator.calculate(
      weightKg: weight,
      heightCm: height,
    );

    // Calculate BMR
    _bmr = BMRCalculator.calculate(
      weightKg: weight,
      heightCm: height,
      age: age,
      isMale: isMale,
    );

    // Calculate TDEE
    final activityFactor = TDEECalculator.getActivityFactor(activityLevel);
    _tdee = TDEECalculator.calculate(
      bmr: _bmr,
      activityFactor: activityFactor,
    );

    // Calculate Calorie Goal
    _calorieGoal = CalorieGoalCalculator.calculate(
      tdee: _tdee,
      goalType: goalType,
      weeklyGoalKg: weeklyGoal,
    );

    if (mounted) {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Get Firebase UID
      final firebaseUid = await SharedPrefsHelper.getFirebaseUid();
      debugPrint('🔑 [UserSetup] Firebase UID: $firebaseUid');

      // Get user name from Firebase User (set during registration)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final userName = firebaseUser?.displayName ?? 'User';
      debugPrint('👤 [UserSetup] User name from Firebase: $userName');

      // Create user model
      final user = UserModel(
        firebaseUid: firebaseUid,
        name: userName, // Get from Firebase User instead of userData
        gender: widget.userData['gender'],
        age: widget.userData['age'],
        heightCm: widget.userData['height'],
        weightKg: widget.userData['weight'],
        goalType: widget.userData['goalType'],
        targetWeightKg: widget.userData['targetWeight'],
        weeklyGoalKg: widget.userData['weeklyGoal'] ?? 0.0,
        activityLevel: widget.userData['activityLevel'],
        bmi: _bmi,
        bmr: _bmr,
        tdee: _tdee,
        calorieGoal: _calorieGoal,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to database
      final db = DatabaseHelper.instance;
      final userId = await db.insertUser(user.toMap());
      debugPrint('✅ [UserSetup] User saved to DB with ID: $userId');

      // Save user ID to SharedPreferences
      await SharedPrefsHelper.saveUserId(userId);
      await SharedPrefsHelper.setNotFirstTime();
      debugPrint('✅ [UserSetup] User ID saved to SharedPrefs');

      // Navigate to Main Navigation
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCalculating) {
      return const Center(
        child: LoadingIndicator(
          message: 'Đang tính toán chỉ số sức khỏe...',
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isSaving,
      message: 'Đang lưu thông tin...',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              '🎉 Hoàn tất!',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Đây là chỉ số sức khỏe và mục tiêu của bạn',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Personal Info Summary (name removed - will be from Firebase)
            _buildSummaryCard(
              'Thông tin cá nhân',
              [
                _buildInfoRow(
                  'Giới tính',
                  widget.userData['gender'] == 'male' ? 'Nam' : 'Nữ',
                ),
                _buildInfoRow('Tuổi', '${widget.userData['age']} tuổi'),
                _buildInfoRow('Chiều cao', '${widget.userData['height']} cm'),
                _buildInfoRow('Cân nặng', '${widget.userData['weight']} kg'),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),

            // Goal Summary
            _buildSummaryCard(
              'Mục tiêu',
              [
                _buildInfoRow(
                  'Loại',
                  CalorieGoalCalculator.getGoalTypeName(
                    widget.userData['goalType'],
                  ),
                ),
                if (widget.userData['targetWeight'] != null)
                  _buildInfoRow(
                    'Cân nặng mục tiêu',
                    '${widget.userData['targetWeight']} kg',
                  ),
                if (widget.userData['weeklyGoal'] != null &&
                    widget.userData['weeklyGoal'] > 0)
                  _buildInfoRow(
                    'Tốc độ',
                    '${widget.userData['weeklyGoal']} kg/tuần',
                  ),
                _buildInfoRow(
                  'Mức độ vận động',
                  TDEECalculator.getActivityLevelName(
                    widget.userData['activityLevel'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),

            // Health Metrics
            _buildMetricsCard(),

            const SizedBox(height: AppDimensions.spaceXL),

            // Finish button
            CustomButton(
              text: AppStrings.done,
              onPressed: _saveAndContinue,
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h6.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '📊 Chỉ số sức khỏe',
            style: AppTextStyles.h6.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // BMI
          _buildMetricItem(
            'BMI',
            _bmi.toStringAsFixed(1),
            BMICalculator.getCategory(_bmi),
            Icons.monitor_weight,
          ),
          const Divider(color: Colors.white24, height: 24),

          // BMR
          _buildMetricItem(
            'BMR',
            '${_bmr.toStringAsFixed(0)} kcal',
            'Calo nghỉ ngơi',
            Icons.bedtime,
          ),
          const Divider(color: Colors.white24, height: 24),

          // TDEE
          _buildMetricItem(
            'TDEE',
            '${_tdee.toStringAsFixed(0)} kcal',
            'Calo tiêu thụ/ngày',
            Icons.local_fire_department,
          ),
          const Divider(color: Colors.white24, height: 24),

          // Calorie Goal
          _buildMetricItem(
            'Mục tiêu Calo',
            '${_calorieGoal.toStringAsFixed(0)} kcal',
            'Calo nên ăn/ngày',
            Icons.flag,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    String description,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

