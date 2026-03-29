/// Calorie Goal Calculator
/// Calculates daily calorie goal based on user's goal (lose/maintain/gain weight)
class CalorieGoalCalculator {
  /// Calorie deficit/surplus per kg
  /// 1 kg of body weight ≈ 7700 calories
  static const double caloriesPerKg = 7700;

  /// Calculate daily calorie goal
  /// 
  /// Parameters:
  /// - tdee: Total Daily Energy Expenditure
  /// - goalType: 'lose', 'maintain', or 'gain'
  /// - weeklyGoalKg: Target weight change per week (e.g., 0.5 kg/week)
  static double calculate({
    required double tdee,
    required String goalType,
    double weeklyGoalKg = 0.5,
  }) {
    if (tdee <= 0) {
      throw ArgumentError('TDEE must be a positive value');
    }

    switch (goalType.toLowerCase()) {
      case 'lose':
      case 'lose_weight':
        // Create calorie deficit
        final dailyDeficit = (weeklyGoalKg * caloriesPerKg) / 7;
        return double.parse((tdee - dailyDeficit).toStringAsFixed(0));

      case 'maintain':
      case 'maintain_weight':
        // No deficit or surplus
        return tdee;

      case 'gain':
      case 'gain_weight':
        // Create calorie surplus
        final dailySurplus = (weeklyGoalKg * caloriesPerKg) / 7;
        return double.parse((tdee + dailySurplus).toStringAsFixed(0));

      default:
        return tdee; // Default to maintenance
    }
  }

  /// Calculate estimated time to reach goal (in weeks)
  static int calculateTimeToGoal({
    required double currentWeight,
    required double targetWeight,
    required double weeklyGoalKg,
  }) {
    if (weeklyGoalKg <= 0) {
      throw ArgumentError('Weekly goal must be positive');
    }

    final weightDifference = (targetWeight - currentWeight).abs();
    final weeks = (weightDifference / weeklyGoalKg).ceil();
    return weeks;
  }

  /// Get recommended weekly goal based on goal type
  static List<double> getRecommendedWeeklyGoals(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'lose':
      case 'lose_weight':
        return [0.25, 0.5, 0.75, 1.0]; // Safe weight loss rates
      case 'gain':
      case 'gain_weight':
        return [0.25, 0.5, 0.75, 1.0]; // Safe weight gain rates
      default:
        return [0.0]; // Maintenance
    }
  }

  /// Get goal type name in Vietnamese
  static String getGoalTypeName(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'lose':
      case 'lose_weight':
        return 'Giảm cân';
      case 'maintain':
      case 'maintain_weight':
        return 'Giữ cân';
      case 'gain':
      case 'gain_weight':
        return 'Tăng cân';
      default:
        return 'Giữ cân';
    }
  }

  /// Get goal type description
  static String getGoalTypeDescription(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'lose':
      case 'lose_weight':
        return 'Giảm cân một cách lành mạnh và bền vững';
      case 'maintain':
      case 'maintain_weight':
        return 'Duy trì cân nặng hiện tại';
      case 'gain':
      case 'gain_weight':
        return 'Tăng cân và khối lượng cơ bắp';
      default:
        return 'Duy trì cân nặng hiện tại';
    }
  }

  /// Get goal type icon
  static String getGoalTypeIcon(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'lose':
      case 'lose_weight':
        return '📉';
      case 'maintain':
      case 'maintain_weight':
        return '⚖️';
      case 'gain':
      case 'gain_weight':
        return '📈';
      default:
        return '⚖️';
    }
  }

  /// Validate weekly goal
  static bool isWeeklyGoalSafe(String goalType, double weeklyGoalKg) {
    // Safe weight change is 0.25-1.0 kg per week
    if (goalType.toLowerCase() == 'maintain' || goalType.toLowerCase() == 'maintain_weight') {
      return weeklyGoalKg == 0;
    }
    return weeklyGoalKg >= 0.25 && weeklyGoalKg <= 1.0;
  }

  /// Get warning message for unsafe weekly goal
  static String? getWeeklyGoalWarning(String goalType, double weeklyGoalKg) {
    if (isWeeklyGoalSafe(goalType, weeklyGoalKg)) {
      return null;
    }

    if (weeklyGoalKg < 0.25) {
      return 'Tốc độ thay đổi cân nặng quá chậm. Khuyến nghị: 0.25-1.0 kg/tuần';
    } else if (weeklyGoalKg > 1.0) {
      return 'Tốc độ thay đổi cân nặng quá nhanh có thể không an toàn. Khuyến nghị: 0.25-1.0 kg/tuần';
    }

    return null;
  }
}

