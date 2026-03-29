// BMR Calculator Unit Tests
// 
// Tests for Basal Metabolic Rate calculation using Mifflin-St Jeor equation
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter_test/flutter_test.dart';
import 'package:calocount_app/core/utils/bmr_calculator.dart';

void main() {
  group('BMRCalculator Tests', () {
    test('Calculate BMR - Male, 25 years, 70kg, 170cm', () {
      // Arrange
      const double weightKg = 70.0;
      const double heightCm = 170.0;
      const int age = 25;
      const bool isMale = true;
      
      // Act
      final bmr = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        isMale: isMale,
      );
      
      // Assert
      // BMR (male) = 10 * weight + 6.25 * height - 5 * age + 5
      // = 10 * 70 + 6.25 * 170 - 5 * 25 + 5
      // = 700 + 1062.5 - 125 + 5 = 1642.5
      expect(bmr, closeTo(1642.5, 0.5));
    });
    
    test('Calculate BMR - Female, 25 years, 60kg, 160cm', () {
      // Arrange
      const double weightKg = 60.0;
      const double heightCm = 160.0;
      const int age = 25;
      const bool isMale = false;
      
      // Act
      final bmr = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        isMale: isMale,
      );
      
      // Assert
      // BMR (female) = 10 * weight + 6.25 * height - 5 * age - 161
      // = 10 * 60 + 6.25 * 160 - 5 * 25 - 161
      // = 600 + 1000 - 125 - 161 = 1314
      expect(bmr, closeTo(1314.0, 0.5));
    });
    
    test('Calculate BMR - Male vs Female with same parameters', () {
      // Arrange
      const double weightKg = 70.0;
      const double heightCm = 170.0;
      const int age = 30;
      
      // Act
      final bmrMale = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        isMale: true,
      );
      
      final bmrFemale = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        isMale: false,
      );
      
      // Assert
      // Male BMR should be higher than female BMR by 166 (5 - (-161))
      expect(bmrMale - bmrFemale, closeTo(166.0, 0.5));
      expect(bmrMale, greaterThan(bmrFemale));
    });
    
    test('Calculate BMR - Age impact (younger vs older)', () {
      // Arrange
      const double weightKg = 70.0;
      const double heightCm = 170.0;
      const bool isMale = true;
      
      // Act
      final bmrYoung = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: 25,
        isMale: isMale,
      );
      
      final bmrOld = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: 55,
        isMale: isMale,
      );
      
      // Assert
      // BMR decreases with age: 5 calories per year
      // Difference should be: 5 * (55 - 25) = 150 calories
      expect(bmrYoung - bmrOld, closeTo(150.0, 0.5));
      expect(bmrYoung, greaterThan(bmrOld));
    });
    
    test('Calculate BMR - Weight impact', () {
      // Arrange
      const double heightCm = 170.0;
      const int age = 30;
      const bool isMale = true;
      
      // Act
      final bmrLight = BMRCalculator.calculate(
        weightKg: 60.0,
        heightCm: heightCm,
        age: age,
        isMale: isMale,
      );
      
      final bmrHeavy = BMRCalculator.calculate(
        weightKg: 80.0,
        heightCm: heightCm,
        age: age,
        isMale: isMale,
      );
      
      // Assert
      // BMR increases with weight: 10 calories per kg
      // Difference should be: 10 * (80 - 60) = 200 calories
      expect(bmrHeavy - bmrLight, closeTo(200.0, 0.5));
    });
    
    test('Calculate BMR - Height impact', () {
      // Arrange
      const double weightKg = 70.0;
      const int age = 30;
      const bool isMale = true;
      
      // Act
      final bmrShort = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: 160.0,
        age: age,
        isMale: isMale,
      );
      
      final bmrTall = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: 180.0,
        age: age,
        isMale: isMale,
      );
      
      // Assert
      // BMR increases with height: 6.25 calories per cm
      // Difference should be: 6.25 * (180 - 160) = 125 calories
      expect(bmrTall - bmrShort, closeTo(125.0, 0.5));
    });
    
    test('Calculate BMR - Edge case: Very young person', () {
      // Arrange
      const double weightKg = 50.0;
      const double heightCm = 160.0;
      const int age = 18;
      const bool isMale = true;
      
      // Act
      final bmr = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        isMale: isMale,
      );
      
      // Assert
      expect(bmr, greaterThan(1300.0));
      expect(bmr, lessThan(1600.0));
    });
    
    test('Calculate BMR - Edge case: Elderly person', () {
      // Arrange
      const double weightKg = 65.0;
      const double heightCm = 165.0;
      const int age = 70;
      const bool isMale = false;
      
      // Act
      final bmr = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        isMale: isMale,
      );
      
      // Assert
      expect(bmr, greaterThan(1000.0));
      expect(bmr, lessThan(1400.0));
    });
    
    test('Calculate BMR - BMR should always be positive', () {
      // Arrange
      const double weightKg = 40.0;
      const double heightCm = 150.0;
      const int age = 80;
      const bool isMale = false;
      
      // Act
      final bmr = BMRCalculator.calculate(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        isMale: isMale,
      );
      
      // Assert
      expect(bmr, greaterThan(0.0));
    });
  });
}

