/// Meal Entry Model - Represents a meal logged by the user
class MealEntryModel {
  final String? id; // Changed to String for UUID
  final String? userId; // Changed to String
  final String foodName;
  final String mealType; // breakfast, lunch, dinner, snack
  final DateTime date;
  final String time;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String portionSize;
  final double portionMultiplier;
  final double servingSize; // Added for compatibility
  final double servings; // Added for compatibility
  final String source; // manual, camera, api
  final String? imagePath; // Local path to meal image (from camera/AI)
  final double? confidence; // AI confidence score (0.0 - 1.0)
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
    this.servingSize = 100.0,
    this.servings = 1.0,
    required this.source,
    this.imagePath,
    this.confidence,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert from database map
  factory MealEntryModel.fromMap(Map<String, dynamic> map) {
    return MealEntryModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      foodName: map['food_name'] as String,
      mealType: map['meal_type'] as String,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String? ?? '00:00',
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      portionSize: map['portion_size'] as String? ?? '100g',
      portionMultiplier: (map['portion_multiplier'] as num?)?.toDouble() ?? 1.0,
      servingSize: (map['serving_size'] as num?)?.toDouble() ?? 100.0,
      servings: (map['servings'] as num?)?.toDouble() ?? 1.0,
      source: map['source'] as String? ?? 'manual',
      imagePath: map['image_path'] as String?, // Support both old and new column names
      confidence: (map['confidence'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'food_name': foodName,
      'meal_type': mealType,
      'date': _formatDate(date),
      'time': time,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'portion_size': portionSize,
      'portion_multiplier': portionMultiplier,
      'source': source,
      'image_path': imagePath,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get total calories (already multiplied when saved)
  double get totalCalories => calories;

  /// Get total protein (already multiplied when saved)
  double get totalProtein => protein;

  /// Get total carbs (already multiplied when saved)
  double get totalCarbs => carbs;

  /// Get total fat (already multiplied when saved)
  double get totalFat => fat;

  /// Create a copy with updated fields
  MealEntryModel copyWith({
    String? id,
    String? userId,
    String? foodName,
    String? mealType,
    DateTime? date,
    String? time,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? portionSize,
    double? portionMultiplier,
    double? servingSize,
    double? servings,
    String? source,
    String? imagePath,
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
      servingSize: servingSize ?? this.servingSize,
      servings: servings ?? this.servings,
      source: source ?? this.source,
      imagePath: imagePath ?? this.imagePath,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MealEntryModel(id: $id, foodName: $foodName, mealType: $mealType, calories: ${totalCalories.toStringAsFixed(0)} kcal)';
  }
}

