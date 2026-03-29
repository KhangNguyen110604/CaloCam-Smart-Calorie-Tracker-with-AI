/// BMR Calculator (Basal Metabolic Rate)
/// Uses Mifflin-St Jeor Equation
class BMRCalculator {
  /// Calculate BMR using Mifflin-St Jeor Equation
  /// 
  /// For Men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5
  /// For Women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
  static double calculate({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
      throw ArgumentError('Weight, height, and age must be positive values');
    }

    double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    
    if (isMale) {
      bmr += 5;
    } else {
      bmr -= 161;
    }

    return double.parse(bmr.toStringAsFixed(0));
  }

  /// Get BMR description
  static String getDescription() {
    return 'BMR (Basal Metabolic Rate) là lượng calo cơ thể cần để duy trì các chức năng sống cơ bản khi nghỉ ngơi hoàn toàn.';
  }
}

