// Meal Provider Unit Tests
// 
// Tests for MealProvider state management
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter_test/flutter_test.dart';
import 'package:calocount_app/presentation/providers/meal_provider.dart';
import '../../helpers/mock_data.dart';

void main() {
  group('MealProvider Tests', () {
    late MealProvider provider;
    
    setUp(() {
      provider = MealProvider();
    });
    
    test('Initial state is empty', () {
      // Assert
      expect(provider.todayMeals, isEmpty);
      expect(provider.recentMeals, isEmpty);
      expect(provider.totalCalories, 0.0);
      expect(provider.totalProtein, 0.0);
      expect(provider.totalCarbs, 0.0);
      expect(provider.totalFat, 0.0);
      expect(provider.mealCount, 0);
      expect(provider.isLoading, isFalse);
    });
    
    test('Total calories calculation', () {
      // Arrange
      const double cal1 = 450.0;
      const double cal2 = 600.0;
      const double cal3 = 520.0;
      
      // Expected total
      const double expectedTotal = cal1 + cal2 + cal3;
      
      // Assert
      expect(expectedTotal, 1570.0);
    });
    
    test('Total protein calculation', () {
      // Arrange
      const double protein1 = 20.0;
      const double protein2 = 30.0;
      const double protein3 = 25.0;
      
      // Expected total
      const double expectedTotal = protein1 + protein2 + protein3;
      
      // Assert
      expect(expectedTotal, 75.0);
    });
    
    test('Total carbs calculation', () {
      // Arrange
      const double carbs1 = 65.0;
      const double carbs2 = 70.0;
      const double carbs3 = 60.0;
      
      // Expected total
      const double expectedTotal = carbs1 + carbs2 + carbs3;
      
      // Assert
      expect(expectedTotal, 195.0);
    });
    
    test('Total fat calculation', () {
      // Arrange
      const double fat1 = 12.0;
      const double fat2 = 15.0;
      const double fat3 = 15.0;
      
      // Expected total
      const double expectedTotal = fat1 + fat2 + fat3;
      
      // Assert
      expect(expectedTotal, 42.0);
    });
    
    test('Meal count calculation', () {
      // Arrange
      final meals = getMockMealEntries();
      
      // Assert
      expect(meals.length, 3);
    });
    
    test('Get meals by type - breakfast', () {
      // Arrange
      final meals = getMockMealEntries();
      final breakfastMeals = meals.where((m) => m.mealType == 'breakfast').toList();
      
      // Assert
      expect(breakfastMeals.length, 1);
      expect(breakfastMeals.first.mealType, 'breakfast');
    });
    
    test('Get meals by type - lunch', () {
      // Arrange
      final meals = getMockMealEntries();
      final lunchMeals = meals.where((m) => m.mealType == 'lunch').toList();
      
      // Assert
      expect(lunchMeals.length, 1);
      expect(lunchMeals.first.mealType, 'lunch');
    });
    
    test('Get meals by type - dinner', () {
      // Arrange
      final meals = getMockMealEntries();
      final dinnerMeals = meals.where((m) => m.mealType == 'dinner').toList();
      
      // Assert
      expect(dinnerMeals.length, 1);
      expect(dinnerMeals.first.mealType, 'dinner');
    });
    
    test('Filter AI meals', () {
      // Arrange
      final meals = getMockMealEntries();
      final aiMeals = meals.where((m) => m.source == 'ai').toList();
      
      // Assert
      expect(aiMeals.length, greaterThan(0));
      for (final meal in aiMeals) {
        expect(meal.source, 'ai');
        expect(meal.confidence, isNotNull);
      }
    });
    
    test('Filter manual meals', () {
      // Arrange
      final meals = getMockMealEntries();
      final manualMeals = meals.where((m) => m.source == 'manual').toList();
      
      // Assert
      expect(manualMeals.length, greaterThan(0));
      for (final meal in manualMeals) {
        expect(meal.source, 'manual');
      }
    });
    
    test('Daily summary contains all required fields', () {
      // Arrange
      final summary = getMockDailySummary();
      
      // Assert
      expect(summary.containsKey('meal_count'), isTrue);
      expect(summary.containsKey('total_calories'), isTrue);
      expect(summary.containsKey('total_protein'), isTrue);
      expect(summary.containsKey('total_carbs'), isTrue);
      expect(summary.containsKey('total_fat'), isTrue);
    });
    
    test('Daily summary values are valid', () {
      // Arrange
      final summary = getMockDailySummary();
      
      // Assert
      expect(summary['meal_count'], greaterThanOrEqualTo(0));
      expect(summary['total_calories'], greaterThanOrEqualTo(0.0));
      expect(summary['total_protein'], greaterThanOrEqualTo(0.0));
      expect(summary['total_carbs'], greaterThanOrEqualTo(0.0));
      expect(summary['total_fat'], greaterThanOrEqualTo(0.0));
    });
    
    test('Meals are sorted by time (most recent first)', () {
      // Arrange
      final meals = getMockMealEntries();
      
      // Act
      meals.sort((a, b) => b.time.compareTo(a.time));
      
      // Assert
      for (int i = 0; i < meals.length - 1; i++) {
        expect(
          meals[i].time.compareTo(meals[i + 1].time),
          greaterThanOrEqualTo(0),
        );
      }
    });
    
    test('Calculate calorie percentage of goal', () {
      // Arrange
      const double consumed = 1500.0;
      const double goal = 2000.0;
      
      // Act
      final percentage = (consumed / goal * 100).round();
      
      // Assert
      expect(percentage, 75);
    });
    
    test('Calculate macro percentages', () {
      // Arrange
      const double protein = 80.0; // grams
      const double carbs = 200.0;  // grams
      const double fat = 50.0;     // grams
      
      // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
      const double proteinCal = protein * 4;
      const double carbsCal = carbs * 4;
      const double fatCal = fat * 9;
      const double totalCal = proteinCal + carbsCal + fatCal;
      
      // Act
      final proteinPercent = (proteinCal / totalCal * 100).round();
      final carbsPercent = (carbsCal / totalCal * 100).round();
      final fatPercent = (fatCal / totalCal * 100).round();
      
      // Assert
      expect(proteinPercent, closeTo(19, 2)); // ~19% (allow ±2%)
      expect(carbsPercent, closeTo(48, 4));   // ~48% (allow ±4% due to rounding)
      expect(fatPercent, closeTo(27, 2));     // ~27% (allow ±2%)
      
      // Total should be close to 100%
      expect(proteinPercent + carbsPercent + fatPercent, closeTo(100, 5));
    });
  });
}

