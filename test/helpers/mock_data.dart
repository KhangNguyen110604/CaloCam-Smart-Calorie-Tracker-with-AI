// Mock Data for Testing
// 
// Provides sample data for unit and widget tests
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:calocount_app/data/models/meal_entry_model.dart';
import 'package:calocount_app/data/models/food_model.dart';

/// Mock user profile data
Map<String, dynamic> getMockUserProfile() {
  final now = DateTime.now().toIso8601String();
  return {
    'id': 1,
    'name': 'Test User',
    'gender': 'male',
    'age': 25,
    'height_cm': 170.0,
    'weight_kg': 70.0,
    'goal_type': 'maintain',
    'target_weight_kg': 70.0,
    'weekly_goal_kg': 0.0,
    'activity_level': 'moderate',
    'bmi': 24.2,
    'bmr': 1680.0,
    'tdee': 2310.0,
    'calorie_goal': 2310.0,
    'created_at': now,
    'updated_at': now,
  };
}

/// Mock food items
List<FoodModel> getMockFoods() {
  return [
    FoodModel(
      id: 1, // ✅ Changed to int
      name: 'Cơm trắng',
      calories: 130,
      protein: 2.7,
      carbs: 28.0,
      fat: 0.3,
      portionSize: '100g',
      category: 'staple',
    ),
    FoodModel(
      id: 2, // ✅ Changed to int
      name: 'Phở bò',
      calories: 450,
      protein: 20.0,
      carbs: 65.0,
      fat: 12.0,
      portionSize: '1 tô',
      category: 'meal',
    ),
    FoodModel(
      id: 3, // ✅ Changed to int
      name: 'Bánh mì thịt',
      calories: 380,
      protein: 15.0,
      carbs: 45.0,
      fat: 14.0,
      portionSize: '1 ổ',
      category: 'meal',
    ),
    FoodModel(
      id: 4, // ✅ Changed to int
      name: 'Cà phê sữa',
      calories: 150,
      protein: 3.0,
      carbs: 20.0,
      fat: 6.0,
      portionSize: '1 ly',
      category: 'beverage',
    ),
  ];
}

/// Mock meal entries
List<MealEntryModel> getMockMealEntries() {
  final now = DateTime.now();
  
  return [
    MealEntryModel(
      id: '1',
      userId: '1', // ✅ Changed to String
      date: now,
      time: '07:30',
      mealType: 'breakfast',
      foodName: 'Phở bò',
      calories: 450,
      protein: 20.0,
      carbs: 65.0,
      fat: 12.0,
      portionSize: '1 tô',
      source: 'ai',
      confidence: 0.95,
      imagePath: null,
    ),
    MealEntryModel(
      id: '2',
      userId: '1', // ✅ Changed to String
      date: now,
      time: '12:00',
      mealType: 'lunch',
      foodName: 'Cơm gà',
      calories: 650,
      protein: 35.0,
      carbs: 75.0,
      fat: 18.0,
      portionSize: '1 đĩa',
      source: 'manual',
      confidence: null,
      imagePath: null,
    ),
    MealEntryModel(
      id: '3',
      userId: '1', // ✅ Changed to String
      date: now,
      time: '18:30',
      mealType: 'dinner',
      foodName: 'Bún chả',
      calories: 520,
      protein: 25.0,
      carbs: 60.0,
      fat: 15.0,
      portionSize: '1 phần',
      source: 'ai',
      confidence: 0.88,
      imagePath: null,
    ),
  ];
}

/// Mock meal entry with image
MealEntryModel getMockMealWithImage() {
  return MealEntryModel(
    id: '4',
    userId: '1', // ✅ Changed to String
    date: DateTime.now(),
    time: '10:00',
    mealType: 'snack',
    foodName: 'Bánh mì thịt',
    calories: 380,
    protein: 15.0,
    carbs: 45.0,
    fat: 14.0,
    portionSize: '1 ổ',
    source: 'ai',
    confidence: 0.92,
    imagePath: '/mock/path/to/image.jpg',
  );
}

/// Mock daily summary
Map<String, dynamic> getMockDailySummary() {
  return {
    'meal_count': 3,
    'total_calories': 1620.0,
    'total_protein': 80.0,
    'total_carbs': 200.0,
    'total_fat': 45.0,
  };
}

/// Mock weekly progress data
List<Map<String, dynamic>> getMockWeeklyProgress() {
  final now = DateTime.now();
  final List<Map<String, dynamic>> weekData = [];
  
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    weekData.add({
      'date': date.toIso8601String().split('T')[0],
      'total_calories': 1800 + (i * 100).toDouble(),
      'total_protein': 80 + (i * 5).toDouble(),
      'total_carbs': 200 + (i * 10).toDouble(),
      'total_fat': 50 + (i * 3).toDouble(),
    });
  }
  
  return weekData;
}

/// Mock weight history
List<Map<String, dynamic>> getMockWeightHistory() {
  final now = DateTime.now();
  final List<Map<String, dynamic>> weights = [];
  
  for (int i = 30; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    weights.add({
      'id': i + 1,
      'user_id': 1,
      'weight_kg': 70.0 + (i % 5) * 0.5 - 1.0,
      'date': date.toIso8601String().split('T')[0],
      'note': i % 7 == 0 ? 'Weekly check' : null,
    });
  }
  
  return weights;
}

/// Mock water intake
Map<String, dynamic> getMockWaterIntake() {
  final now = DateTime.now();
  return {
    'id': 1,
    'user_id': 1,
    'date': now.toIso8601String().split('T')[0],
    'amount_ml': 1500,
    'goal_ml': 2000,
  };
}

/// Mock API response for AI food recognition
Map<String, dynamic> getMockAIResponse() {
  return {
    'food_name': 'Phở bò',
    'calories': 450,
    'protein': 20.0,
    'carbs': 65.0,
    'fat': 12.0,
    'portion_size': '1 tô',
    'confidence': 0.95,
  };
}

/// Mock error AI response
Map<String, dynamic> getMockAIErrorResponse() {
  return {
    'error': 'Unable to recognize food',
    'message': 'Please try again with a clearer image',
  };
}

