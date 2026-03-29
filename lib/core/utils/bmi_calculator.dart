/// BMI Calculator
class BMICalculator {
  /// Calculate BMI (Body Mass Index)
  /// Formula: weight(kg) / (height(m))²
  static double calculate({
    required double weightKg,
    required double heightCm,
  }) {
    if (weightKg <= 0 || heightCm <= 0) {
      throw ArgumentError('Weight and height must be positive values');
    }

    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Get BMI category
  static String getCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Thiếu cân';
    } else if (bmi >= 18.5 && bmi < 23) {
      return 'Bình thường';
    } else if (bmi >= 23 && bmi < 25) {
      return 'Thừa cân';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Béo phì độ I';
    } else {
      return 'Béo phì độ II';
    }
  }

  /// Get BMI category color
  static String getCategoryColor(double bmi) {
    if (bmi < 18.5) {
      return 'warning'; // Yellow
    } else if (bmi >= 18.5 && bmi < 23) {
      return 'success'; // Green
    } else if (bmi >= 23 && bmi < 25) {
      return 'warning'; // Yellow
    } else {
      return 'error'; // Red
    }
  }

  /// Get health advice based on BMI
  static String getAdvice(double bmi) {
    if (bmi < 18.5) {
      return 'Bạn nên tăng cân để đạt chỉ số BMI lý tưởng';
    } else if (bmi >= 18.5 && bmi < 23) {
      return 'Chỉ số BMI của bạn ở mức lý tưởng. Hãy duy trì!';
    } else if (bmi >= 23 && bmi < 25) {
      return 'Bạn đang thừa cân. Nên giảm cân nhẹ';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Bạn đang béo phì độ I. Nên giảm cân';
    } else {
      return 'Bạn đang béo phì độ II. Cần giảm cân ngay';
    }
  }
}

