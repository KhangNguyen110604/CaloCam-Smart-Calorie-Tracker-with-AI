// BMI Calculator Unit Tests
// 
// Tests for BMI calculation logic
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter_test/flutter_test.dart';
import 'package:calocount_app/core/utils/bmi_calculator.dart';

void main() {
  group('BMICalculator Tests', () {
    test('Calculate BMI - Normal weight', () {
      // Arrange
      const double weightKg = 70.0;
      const double heightCm = 170.0;
      
      // Act
      final bmi = BMICalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
      );
      
      // Assert
      expect(bmi, closeTo(24.2, 0.1)); // 70 / (1.7^2) = 24.22
    });
    
    test('Calculate BMI - Underweight', () {
      // Arrange
      const double weightKg = 50.0;
      const double heightCm = 170.0;
      
      // Act
      final bmi = BMICalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
      );
      
      // Assert
      expect(bmi, closeTo(17.3, 0.1));
      expect(bmi, lessThan(18.5)); // Underweight threshold
    });
    
    test('Calculate BMI - Overweight', () {
      // Arrange
      const double weightKg = 85.0;
      const double heightCm = 170.0;
      
      // Act
      final bmi = BMICalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
      );
      
      // Assert
      expect(bmi, closeTo(29.4, 0.1));
      expect(bmi, greaterThan(25.0)); // Overweight threshold
    });
    
    test('Calculate BMI - Obese', () {
      // Arrange
      const double weightKg = 100.0;
      const double heightCm = 170.0;
      
      // Act
      final bmi = BMICalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
      );
      
      // Assert
      expect(bmi, closeTo(34.6, 0.1));
      expect(bmi, greaterThan(30.0)); // Obese threshold
    });
    
    test('Calculate BMI - Edge case: Very tall person', () {
      // Arrange
      const double weightKg = 90.0;
      const double heightCm = 200.0;
      
      // Act
      final bmi = BMICalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
      );
      
      // Assert
      expect(bmi, closeTo(22.5, 0.1));
    });
    
    test('Calculate BMI - Edge case: Very short person', () {
      // Arrange
      const double weightKg = 40.0;
      const double heightCm = 150.0;
      
      // Act
      final bmi = BMICalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
      );
      
      // Assert
      expect(bmi, closeTo(17.8, 0.1));
    });
    
    test('Get BMI category - Underweight', () {
      // Act
      final category = BMICalculator.getCategory(17.0);
      
      // Assert
      expect(category, 'Thiếu cân');
    });
    
    test('Get BMI category - Normal', () {
      // Act
      final category = BMICalculator.getCategory(22.0);
      
      // Assert
      expect(category, 'Bình thường');
    });
    
    test('Get BMI category - Overweight (23-25)', () {
      // Act
      final category = BMICalculator.getCategory(24.0); // ✅ Changed to 24.0 (in range 23-25)
      
      // Assert
      expect(category, 'Thừa cân');
    });
    
    test('Get BMI category - Obese class I (25-30)', () {
      // Act
      final category = BMICalculator.getCategory(27.0); // ✅ Changed to 27.0 (in range 25-30)
      
      // Assert
      expect(category, 'Béo phì độ I'); // ✅ Updated expected value
    });
    
    test('Get BMI category - Obese class II (30+)', () {
      // Act
      final category = BMICalculator.getCategory(32.0);
      
      // Assert
      expect(category, 'Béo phì độ II'); // ✅ Updated expected value
    });
    
    test('Get BMI category - Boundary: Exactly 18.5 (Normal)', () {
      // Act
      final category = BMICalculator.getCategory(18.5);
      
      // Assert
      expect(category, 'Bình thường');
    });
    
    test('Get BMI category - Boundary: Exactly 23.0 (Overweight)', () {
      // Act
      final category = BMICalculator.getCategory(23.0); // ✅ Changed to 23.0
      
      // Assert
      expect(category, 'Thừa cân'); // ✅ Asian BMI standard: 23+ is overweight
    });
    
    test('Get BMI category - Boundary: Exactly 25.0 (Obese I)', () {
      // Act
      final category = BMICalculator.getCategory(25.0);
      
      // Assert
      expect(category, 'Béo phì độ I'); // ✅ Updated expected value
    });
    
    test('Get BMI category - Boundary: Exactly 30.0 (Obese II)', () {
      // Act
      final category = BMICalculator.getCategory(30.0);
      
      // Assert
      expect(category, 'Béo phì độ II'); // ✅ Updated expected value
    });
  });
}

