// TDEE Calculator Unit Tests
// 
// Tests for Total Daily Energy Expenditure calculation
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter_test/flutter_test.dart';
import 'package:calocount_app/core/utils/tdee_calculator.dart';

void main() {
  group('TDEECalculator Tests', () {
    const double baseBMR = 1600.0;
    
    test('Calculate TDEE - Sedentary (little or no exercise)', () {
      // Act
      final tdee = TDEECalculator.calculate(
        bmr: baseBMR,
        activityFactor: 1.2, // Sedentary
      );
      
      // Assert
      expect(tdee, closeTo(1920.0, 0.5)); // 1600 * 1.2
    });
    
    test('Calculate TDEE - Lightly active (1-3 days/week)', () {
      // Act
      final tdee = TDEECalculator.calculate(
        bmr: baseBMR,
        activityFactor: 1.375, // Lightly active
      );
      
      // Assert
      expect(tdee, closeTo(2200.0, 0.5)); // 1600 * 1.375
    });
    
    test('Calculate TDEE - Moderately active (3-5 days/week)', () {
      // Act
      final tdee = TDEECalculator.calculate(
        bmr: baseBMR,
        activityFactor: 1.55, // Moderately active
      );
      
      // Assert
      expect(tdee, closeTo(2480.0, 0.5)); // 1600 * 1.55
    });
    
    test('Calculate TDEE - Very active (6-7 days/week)', () {
      // Act
      final tdee = TDEECalculator.calculate(
        bmr: baseBMR,
        activityFactor: 1.725, // Very active
      );
      
      // Assert
      expect(tdee, closeTo(2760.0, 0.5)); // 1600 * 1.725
    });
    
    test('Calculate TDEE - Extra active (very hard exercise)', () {
      // Act
      final tdee = TDEECalculator.calculate(
        bmr: baseBMR,
        activityFactor: 1.9, // Extra active
      );
      
      // Assert
      expect(tdee, closeTo(3040.0, 0.5)); // 1600 * 1.9
    });
    
    test('Get activity factor - Sedentary', () {
      // Act
      final factor = TDEECalculator.getActivityFactor('sedentary');
      
      // Assert
      expect(factor, 1.2);
    });
    
    test('Get activity factor - Light', () {
      // Act
      final factor = TDEECalculator.getActivityFactor('light');
      
      // Assert
      expect(factor, 1.375);
    });
    
    test('Get activity factor - Moderate', () {
      // Act
      final factor = TDEECalculator.getActivityFactor('moderate');
      
      // Assert
      expect(factor, 1.55);
    });
    
    test('Get activity factor - Active', () {
      // Act
      final factor = TDEECalculator.getActivityFactor('active');
      
      // Assert
      expect(factor, 1.725);
    });
    
    test('Get activity factor - Very Active', () {
      // Act
      final factor = TDEECalculator.getActivityFactor('very_active');
      
      // Assert
      expect(factor, 1.725); // ✅ Fixed: veryActive = 1.725
    });
    
    test('Get activity factor - Extra Active', () {
      // Act
      final factor = TDEECalculator.getActivityFactor('extra_active');
      
      // Assert
      expect(factor, 1.9); // ✅ extraActive = 1.9
    });
    
    test('Get activity factor - Unknown (defaults to moderate)', () {
      // Act
      final factor = TDEECalculator.getActivityFactor('unknown');
      
      // Assert
      expect(factor, 1.55); // Should default to moderate
    });
    
    test('TDEE should always be greater than BMR', () {
      // Arrange
      const double testBMR = 1500.0;
      
      // Act
      final tdeeSedentary = TDEECalculator.calculate(
        bmr: testBMR,
        activityFactor: 1.2,
      );
      
      // Assert
      expect(tdeeSedentary, greaterThan(testBMR));
    });
    
    test('TDEE increases with activity level', () {
      // Arrange
      const double testBMR = 1600.0;
      
      // Act
      final tdeeSedentary = TDEECalculator.calculate(
        bmr: testBMR,
        activityFactor: TDEECalculator.getActivityFactor('sedentary'),
      );
      
      final tdeeModerate = TDEECalculator.calculate(
        bmr: testBMR,
        activityFactor: TDEECalculator.getActivityFactor('moderate'),
      );
      
      final tdeeVeryActive = TDEECalculator.calculate(
        bmr: testBMR,
        activityFactor: TDEECalculator.getActivityFactor('very_active'),
      );
      
      // Assert
      expect(tdeeModerate, greaterThan(tdeeSedentary));
      expect(tdeeVeryActive, greaterThan(tdeeModerate));
    });
    
    test('TDEE with high BMR', () {
      // Arrange
      const double highBMR = 2500.0;
      
      // Act
      final tdee = TDEECalculator.calculate(
        bmr: highBMR,
        activityFactor: 1.55,
      );
      
      // Assert
      expect(tdee, closeTo(3875.0, 0.5));
      expect(tdee, greaterThan(3500.0));
    });
    
    test('TDEE with low BMR', () {
      // Arrange
      const double lowBMR = 1200.0;
      
      // Act
      final tdee = TDEECalculator.calculate(
        bmr: lowBMR,
        activityFactor: 1.2,
      );
      
      // Assert
      expect(tdee, closeTo(1440.0, 0.5));
    });
  });
}

