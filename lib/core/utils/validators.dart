/// Input Validators
class Validators {
  Validators._();

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Trường này"} là bắt buộc';
    }
    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên';
    }
    if (value.trim().length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  /// Validate age
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tuổi';
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'Tuổi phải là số';
    }

    if (age < 10 || age > 120) {
      return 'Tuổi phải từ 10 đến 120';
    }

    return null;
  }

  /// Validate height (cm)
  static String? height(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập chiều cao';
    }

    final height = double.tryParse(value);
    if (height == null) {
      return 'Chiều cao phải là số';
    }

    if (height < 100 || height > 250) {
      return 'Chiều cao phải từ 100cm đến 250cm';
    }

    return null;
  }

  /// Validate weight (kg)
  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập cân nặng';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Cân nặng phải là số';
    }

    if (weight < 20 || weight > 300) {
      return 'Cân nặng phải từ 20kg đến 300kg';
    }

    return null;
  }

  /// Validate calories
  static String? calories(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập calories';
    }

    final calories = double.tryParse(value);
    if (calories == null) {
      return 'Calories phải là số';
    }

    if (calories < 0) {
      return 'Calories không thể âm';
    }

    if (calories > 10000) {
      return 'Calories quá cao';
    }

    return null;
  }

  /// Validate macros (protein, carbs, fat)
  static String? macro(String? value, String macroName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final macro = double.tryParse(value);
    if (macro == null) {
      return '$macroName phải là số';
    }

    if (macro < 0) {
      return '$macroName không thể âm';
    }

    if (macro > 1000) {
      return '$macroName quá cao';
    }

    return null;
  }

  /// Validate email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Giá trị"} là bắt buộc';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? "Giá trị"} phải là số';
    }

    if (number <= 0) {
      return '${fieldName ?? "Giá trị"} phải lớn hơn 0';
    }

    return null;
  }

  /// Validate number in range
  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Giá trị"} là bắt buộc';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? "Giá trị"} phải là số';
    }

    if (number < min || number > max) {
      return '${fieldName ?? "Giá trị"} phải từ $min đến $max';
    }

    return null;
  }
}

