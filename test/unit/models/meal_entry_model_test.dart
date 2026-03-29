// Meal Entry Model Unit Tests
// 
// Tests for MealEntryModel data class
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter_test/flutter_test.dart';
import 'package:calocount_app/data/models/meal_entry_model.dart';

void main() {
  group('MealEntryModel Tests', () {
    test('Create meal entry model', () {
      // Arrange & Act
      final meal = MealEntryModel(
        id: '1',
        userId: '1', // ✅ Changed to String
        date: DateTime(2025, 10, 21),
        time: '12:00',
        mealType: 'lunch',
        foodName: 'Phở bò',
        calories: 450,
        protein: 20.0,
        carbs: 65.0,
        fat: 12.0,
        portionSize: '1 tô',
        source: 'ai',
        confidence: 0.95,
        imagePath: '/path/to/image.jpg',
      );
      
      // Assert
      expect(meal.id, '1');
      expect(meal.foodName, 'Phở bò');
      expect(meal.calories, 450);
      expect(meal.source, 'ai');
      expect(meal.confidence, 0.95);
    });
    
    test('Create meal entry without optional fields', () {
      // Arrange & Act
      final meal = MealEntryModel(
        id: '2',
        userId: '1', // ✅ Changed to String
        date: DateTime(2025, 10, 21),
        time: '12:00',
        mealType: 'lunch',
        foodName: 'Cơm gà',
        calories: 600,
        protein: 30.0,
        carbs: 70.0,
        fat: 15.0,
        portionSize: '1 đĩa',
        source: 'manual',
        confidence: null,
        imagePath: null,
      );
      
      // Assert
      expect(meal.confidence, isNull);
      expect(meal.imagePath, isNull);
    });
    
    test('Convert meal entry to map', () {
      // Arrange
      final meal = MealEntryModel(
        id: '1',
        userId: '1', // ✅ Changed to String
        date: DateTime(2025, 10, 21),
        time: '12:00',
        mealType: 'lunch',
        foodName: 'Phở bò',
        calories: 450,
        protein: 20.0,
        carbs: 65.0,
        fat: 12.0,
        portionSize: '1 tô',
        source: 'ai',
        confidence: 0.95,
        imagePath: '/path/to/image.jpg',
      );
      
      // Act
      final map = meal.toMap();
      
      // Assert
      expect(map['id'], '1');
      expect(map['user_id'], '1'); // ✅ Changed to String
      expect(map['date'], '2025-10-21');
      expect(map['time'], '12:00');
      expect(map['meal_type'], 'lunch');
      expect(map['food_name'], 'Phở bò');
      expect(map['calories'], 450.0);
      expect(map['protein'], 20.0);
      expect(map['carbs'], 65.0);
      expect(map['fat'], 12.0);
      expect(map['portion_size'], '1 tô');
      expect(map['source'], 'ai');
      expect(map['confidence'], 0.95);
      expect(map['image_path'], '/path/to/image.jpg');
    });
    
    test('Convert map to meal entry', () {
      // Arrange
      final map = {
        'id': '1',
        'user_id': '1', // ✅ Changed to String
        'date': '2025-10-21',
        'time': '12:00',
        'meal_type': 'lunch',
        'food_name': 'Phở bò',
        'calories': 450.0,
        'protein': 20.0,
        'carbs': 65.0,
        'fat': 12.0,
        'portion_size': '1 tô',
        'portion_multiplier': 1.0, // ✅ Added required field
        'source': 'ai',
        'confidence': 0.95,
        'image_path': '/path/to/image.jpg',
        'created_at': '2025-10-21T12:00:00.000', // ✅ Added required field
      };
      
      // Act
      final meal = MealEntryModel.fromMap(map);
      
      // Assert
      expect(meal.id, '1');
      expect(meal.userId, '1'); // ✅ Changed to String
      expect(meal.date.year, 2025);
      expect(meal.date.month, 10);
      expect(meal.date.day, 21);
      expect(meal.time, '12:00');
      expect(meal.mealType, 'lunch');
      expect(meal.foodName, 'Phở bò');
      expect(meal.calories, 450.0);
      expect(meal.protein, 20.0);
      expect(meal.carbs, 65.0);
      expect(meal.fat, 12.0);
      expect(meal.portionSize, '1 tô');
      expect(meal.source, 'ai');
      expect(meal.confidence, 0.95);
      expect(meal.imagePath, '/path/to/image.jpg');
    });
    
    test('Convert map with null optional fields', () {
      // Arrange
      final map = {
        'id': '2',
        'user_id': '1', // ✅ Changed to String
        'date': '2025-10-21',
        'time': '18:00',
        'meal_type': 'dinner',
        'food_name': 'Cơm gà',
        'calories': 600.0,
        'protein': 30.0,
        'carbs': 70.0,
        'fat': 15.0,
        'portion_size': '1 đĩa',
        'portion_multiplier': 1.0, // ✅ Added required field
        'source': 'manual',
        'confidence': null,
        'image_path': null,
        'created_at': '2025-10-21T18:00:00.000', // ✅ Added required field
      };
      
      // Act
      final meal = MealEntryModel.fromMap(map);
      
      // Assert
      expect(meal.confidence, isNull);
      expect(meal.imagePath, isNull);
    });
    
    test('Round trip conversion - toMap then fromMap', () {
      // Arrange
      final original = MealEntryModel(
        id: '3',
        userId: '1', // ✅ Changed to String
        date: DateTime(2025, 10, 21, 14, 30),
        time: '14:30',
        mealType: 'snack',
        foodName: 'Bánh mì',
        calories: 350,
        protein: 12.0,
        carbs: 45.0,
        fat: 10.0,
        portionSize: '1 ổ',
        source: 'ai',
        confidence: 0.88,
        imagePath: '/path/to/banh_mi.jpg',
      );
      
      // Act
      final map = original.toMap();
      final converted = MealEntryModel.fromMap(map);
      
      // Assert
      expect(converted.id, original.id);
      expect(converted.userId, original.userId);
      expect(converted.date.year, original.date.year);
      expect(converted.date.month, original.date.month);
      expect(converted.date.day, original.date.day);
      expect(converted.time, original.time);
      expect(converted.mealType, original.mealType);
      expect(converted.foodName, original.foodName);
      expect(converted.calories, original.calories);
      expect(converted.protein, original.protein);
      expect(converted.carbs, original.carbs);
      expect(converted.fat, original.fat);
      expect(converted.portionSize, original.portionSize);
      expect(converted.source, original.source);
      expect(converted.confidence, original.confidence);
      expect(converted.imagePath, original.imagePath);
    });
    
    test('Meal types are valid', () {
      // Arrange
      final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
      
      // Act & Assert
      for (final type in mealTypes) {
        final meal = MealEntryModel(
          id: '1',
          userId: '1', // ✅ Changed to String
          date: DateTime.now(),
          time: '12:00',
          mealType: type,
          foodName: 'Test food',
          calories: 100,
          protein: 10.0,
          carbs: 20.0,
          fat: 5.0,
          portionSize: '1 serving',
          source: 'manual',
          confidence: null,
          imagePath: null,
        );
        
        expect(meal.mealType, type);
      }
    });
    
    test('Source types are valid', () {
      // Arrange
      final sources = ['ai', 'manual'];
      
      // Act & Assert
      for (final source in sources) {
        final meal = MealEntryModel(
          id: '1',
          userId: '1', // ✅ Changed to String
          date: DateTime.now(),
          time: '12:00',
          mealType: 'lunch',
          foodName: 'Test food',
          calories: 100,
          protein: 10.0,
          carbs: 20.0,
          fat: 5.0,
          portionSize: '1 serving',
          source: source,
          confidence: source == 'ai' ? 0.9 : null,
          imagePath: null,
        );
        
        expect(meal.source, source);
      }
    });
    
    test('Calories are always positive', () {
      // Arrange & Act
      final meal = MealEntryModel(
        id: '1',
        userId: '1', // ✅ Changed to String
        date: DateTime.now(),
        time: '12:00',
        mealType: 'lunch',
        foodName: 'Test food',
        calories: 450,
        protein: 20.0,
        carbs: 65.0,
        fat: 12.0,
        portionSize: '1 serving',
        source: 'manual',
        confidence: null,
        imagePath: null,
      );
      
      // Assert
      expect(meal.calories, greaterThan(0));
    });
    
    test('Macros are non-negative', () {
      // Arrange & Act
      final meal = MealEntryModel(
        id: '1',
        userId: '1', // ✅ Changed to String
        date: DateTime.now(),
        time: '12:00',
        mealType: 'lunch',
        foodName: 'Test food',
        calories: 450,
        protein: 20.0,
        carbs: 65.0,
        fat: 12.0,
        portionSize: '1 serving',
        source: 'manual',
        confidence: null,
        imagePath: null,
      );
      
      // Assert
      expect(meal.protein, greaterThanOrEqualTo(0));
      expect(meal.carbs, greaterThanOrEqualTo(0));
      expect(meal.fat, greaterThanOrEqualTo(0));
    });
    
    test('Confidence is between 0 and 1 for AI source', () {
      // Arrange & Act
      final meal = MealEntryModel(
        id: '1',
        userId: '1', // ✅ Changed to String
        date: DateTime.now(),
        time: '12:00',
        mealType: 'lunch',
        foodName: 'Test food',
        calories: 450,
        protein: 20.0,
        carbs: 65.0,
        fat: 12.0,
        portionSize: '1 serving',
        source: 'ai',
        confidence: 0.87,
        imagePath: null,
      );
      
      // Assert
      expect(meal.confidence, greaterThanOrEqualTo(0));
      expect(meal.confidence, lessThanOrEqualTo(1));
    });
  });
}

