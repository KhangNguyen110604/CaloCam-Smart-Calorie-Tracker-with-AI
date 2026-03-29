/// Meal Entry Model
class MealEntryModel {
  final int? id;
  final int? userId;
  final String foodName;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final DateTime date;
  final DateTime time;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String portionSize;
  final double portionMultiplier; // 1.0 = 1 portion, 0.5 = half portion, etc.
  final String source; // 'camera', 'catalog', 'manual'
  final String? imageUrl;
  final double? confidence; // AI confidence (0-1)
  final DateTime createdAt;

  MealEntryModel({
    this.id,
    this.userId,
    required this.foodName,
    required this.mealType,
    required this.date,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portionSize,
    this.portionMultiplier = 1.0,
    required this.source,
    this.imageUrl,
    this.confidence,
    required this.createdAt,
  });

  /// Get total calories (adjusted by portion multiplier)
  double get totalCalories => calories * portionMultiplier;

  /// Get total protein (adjusted by portion multiplier)
  double get totalProtein => protein * portionMultiplier;

  /// Get total carbs (adjusted by portion multiplier)
  double get totalCarbs => carbs * portionMultiplier;

  /// Get total fat (adjusted by portion multiplier)
  double get totalFat => fat * portionMultiplier;

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'food_name': foodName,
      'meal_type': mealType,
      'date': date.toIso8601String(),
      'time': time.toIso8601String(),
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'portion_size': portionSize,
      'portion_multiplier': portionMultiplier,
      'source': source,
      'image_url': imageUrl,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from Map (database)
  factory MealEntryModel.fromMap(Map<String, dynamic> map) {
    return MealEntryModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      foodName: map['food_name'] as String,
      mealType: map['meal_type'] as String,
      date: DateTime.parse(map['date'] as String),
      time: DateTime.parse(map['time'] as String),
      calories: map['calories'] as double,
      protein: map['protein'] as double,
      carbs: map['carbs'] as double,
      fat: map['fat'] as double,
      portionSize: map['portion_size'] as String,
      portionMultiplier: map['portion_multiplier'] as double? ?? 1.0,
      source: map['source'] as String,
      imageUrl: map['image_url'] as String?,
      confidence: map['confidence'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Copy with
  MealEntryModel copyWith({
    int? id,
    int? userId,
    String? foodName,
    String? mealType,
    DateTime? date,
    DateTime? time,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? portionSize,
    double? portionMultiplier,
    String? source,
    String? imageUrl,
    double? confidence,
    DateTime? createdAt,
  }) {
    return MealEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      mealType: mealType ?? this.mealType,
      date: date ?? this.date,
      time: time ?? this.time,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      portionSize: portionSize ?? this.portionSize,
      portionMultiplier: portionMultiplier ?? this.portionMultiplier,
      source: source ?? this.source,
      imageUrl: imageUrl ?? this.imageUrl,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MealEntryModel(id: $id, foodName: $foodName, mealType: $mealType, '
        'calories: ${totalCalories.toStringAsFixed(0)} kcal, date: $date)';
  }
}

/// Daily Log Model (Summary of a day's meals)
class DailyLogModel {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int mealCount;
  final double calorieGoal;
  final List<MealEntryModel> meals;

  DailyLogModel({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealCount,
    required this.calorieGoal,
    required this.meals,
  });

  /// Get remaining calories
  double get remainingCalories => calorieGoal - totalCalories;

  /// Get calorie progress (0-1)
  double get calorieProgress => totalCalories / calorieGoal;

  /// Check if goal is achieved
  bool get isGoalAchieved {
    // Within 10% of goal is considered achieved
    final difference = (totalCalories - calorieGoal).abs();
    final tolerance = calorieGoal * 0.1;
    return difference <= tolerance;
  }

  /// Get meals by type
  List<MealEntryModel> getMealsByType(String mealType) {
    return meals.where((meal) => meal.mealType == mealType).toList();
  }

  /// Get calories by meal type
  double getCaloriesByMealType(String mealType) {
    return getMealsByType(mealType)
        .fold(0, (sum, meal) => sum + meal.totalCalories);
  }

  /// Factory method to create from meals list
  factory DailyLogModel.fromMeals({
    required DateTime date,
    required List<MealEntryModel> meals,
    required double calorieGoal,
  }) {
    final totalCalories = meals.fold(0.0, (sum, meal) => sum + meal.totalCalories);
    final totalProtein = meals.fold(0.0, (sum, meal) => sum + meal.totalProtein);
    final totalCarbs = meals.fold(0.0, (sum, meal) => sum + meal.totalCarbs);
    final totalFat = meals.fold(0.0, (sum, meal) => sum + meal.totalFat);

    return DailyLogModel(
      date: date,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      mealCount: meals.length,
      calorieGoal: calorieGoal,
      meals: meals,
    );
  }

  @override
  String toString() {
    return 'DailyLogModel(date: $date, totalCalories: ${totalCalories.toStringAsFixed(0)}/${calorieGoal.toStringAsFixed(0)} kcal, '
        'meals: $mealCount)';
  }
}

/// Water Intake Model
class WaterIntakeModel {
  final int? id;
  final int userId;
  final DateTime date;
  final int glasses; // Number of glasses (1 glass = 250ml)
  final int milliliters;

  WaterIntakeModel({
    this.id,
    required this.userId,
    required this.date,
    required this.glasses,
    required this.milliliters,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'glasses': glasses,
      'milliliters': milliliters,
    };
  }

  factory WaterIntakeModel.fromMap(Map<String, dynamic> map) {
    return WaterIntakeModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      date: DateTime.parse(map['date'] as String),
      glasses: map['glasses'] as int,
      milliliters: map['milliliters'] as int,
    );
  }

  WaterIntakeModel copyWith({
    int? id,
    int? userId,
    DateTime? date,
    int? glasses,
    int? milliliters,
  }) {
    return WaterIntakeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      glasses: glasses ?? this.glasses,
      milliliters: milliliters ?? this.milliliters,
    );
  }
}

