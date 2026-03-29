/// TDEE Calculator (Total Daily Energy Expenditure)
class TDEECalculator {
  /// Activity Level Multipliers
  static const double sedentary = 1.2; // Little or no exercise
  static const double lightlyActive = 1.375; // Light exercise 1-3 days/week
  static const double moderatelyActive = 1.55; // Moderate exercise 3-5 days/week
  static const double veryActive = 1.725; // Hard exercise 6-7 days/week
  static const double extraActive = 1.9; // Very hard exercise, physical job

  /// Calculate TDEE
  /// Formula: TDEE = BMR × Activity Factor
  static double calculate({
    required double bmr,
    required double activityFactor,
  }) {
    if (bmr <= 0 || activityFactor <= 0) {
      throw ArgumentError('BMR and activity factor must be positive values');
    }

    final tdee = bmr * activityFactor;
    return double.parse(tdee.toStringAsFixed(0));
  }

  /// Get activity factor from level
  static double getActivityFactor(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return sedentary;
      case 'lightly_active':
      case 'light':
        return lightlyActive;
      case 'moderately_active':
      case 'moderate':
        return moderatelyActive;
      case 'very_active':
      case 'active':
        return veryActive;
      case 'extra_active':
      case 'extremely_active':
        return extraActive;
      default:
        return moderatelyActive; // Default to moderate
    }
  }

  /// Get activity level name
  static String getActivityLevelName(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 'Ít vận động';
      case 'lightly_active':
      case 'light':
        return 'Vận động nhẹ';
      case 'moderately_active':
      case 'moderate':
        return 'Vận động trung bình';
      case 'very_active':
      case 'active':
        return 'Vận động nhiều';
      case 'extra_active':
      case 'extremely_active':
        return 'Vận động rất nhiều';
      default:
        return 'Vận động trung bình';
    }
  }

  /// Get activity level description
  static String getActivityLevelDescription(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 'Ngồi nhiều, ít hoạt động';
      case 'lightly_active':
      case 'light':
        return 'Tập luyện nhẹ 1-3 ngày/tuần';
      case 'moderately_active':
      case 'moderate':
        return 'Tập luyện vừa phải 3-5 ngày/tuần';
      case 'very_active':
      case 'active':
        return 'Tập luyện nặng 6-7 ngày/tuần';
      case 'extra_active':
      case 'extremely_active':
        return 'Vận động viên, tập 2 lần/ngày';
      default:
        return 'Tập luyện vừa phải 3-5 ngày/tuần';
    }
  }

  /// Get TDEE description
  static String getDescription() {
    return 'TDEE (Total Daily Energy Expenditure) là tổng lượng calo cơ thể tiêu thụ trong một ngày, bao gồm cả hoạt động thể chất.';
  }
}

