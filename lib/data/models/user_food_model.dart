/// User Food Model
/// 
/// Represents a custom food created by the user (món ăn của tôi)
/// Can be created manually or from AI food recognition
/// 
/// Properties:
/// - [id]: Unique identifier (UUID)
/// - [userId]: Owner of this food
/// - [name]: Food name (e.g., "Phở gà nhà tôi")
/// - [portionSize]: Standard portion size in grams (default: 100g)
/// - [servingSize]: User-specific serving size
/// - [calories]: Calories per portion
/// - [protein], [carbs], [fat]: Macronutrients in grams
/// - [imagePath]: Local path to food image
/// - [source]: Creation method ('manual' or 'ai_scan')
/// - [aiConfidence]: AI recognition confidence (0-1) if from AI
/// - [isEditable]: Whether user can edit this food (always true for user foods)
/// - [usageCount]: Number of times this food was added to meals
/// - [lastUsedAt]: When this food was last used
/// - [createdAt], [updatedAt]: Timestamps
class UserFoodModel {
  final String id;
  final String userId;
  final String name;
  final double portionSize;
  final double? servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imagePath;
  final String source; // 'manual' or 'ai_scan'
  final double? aiConfidence;
  final bool isEditable;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastUsedAt;
  final int usageCount;

  UserFoodModel({
    required this.id,
    required this.userId,
    required this.name,
    this.portionSize = 100,
    this.servingSize,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.imagePath,
    required this.source,
    this.aiConfidence,
    this.isEditable = true,
    required this.createdAt,
    this.updatedAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  /// Convert model to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'portion_size': portionSize,
      'serving_size': servingSize,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'image_path': imagePath,
      'source': source,
      'ai_confidence': aiConfidence,
      'is_editable': isEditable ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'usage_count': usageCount,
    };
  }

  /// Create model from database Map
  factory UserFoodModel.fromMap(Map<String, dynamic> map) {
    return UserFoodModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      portionSize: (map['portion_size'] as num?)?.toDouble() ?? 100,
      servingSize: (map['serving_size'] as num?)?.toDouble(),
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      imagePath: map['image_path'] as String?,
      source: map['source'] as String,
      aiConfidence: (map['ai_confidence'] as num?)?.toDouble(),
      isEditable: (map['is_editable'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
      lastUsedAt: map['last_used_at'] != null 
          ? DateTime.parse(map['last_used_at'] as String) 
          : null,
      usageCount: (map['usage_count'] as int?) ?? 0,
    );
  }

  /// Create a copy with modified fields
  /// 
  /// Useful for updating specific properties while keeping others unchanged
  /// Example:
  /// ```dart
  /// final updated = food.copyWith(
  ///   name: 'New name',
  ///   calories: 200,
  ///   updatedAt: DateTime.now(),
  /// );
  /// ```
  UserFoodModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? portionSize,
    double? servingSize,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? imagePath,
    String? source,
    double? aiConfidence,
    bool? isEditable,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return UserFoodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      portionSize: portionSize ?? this.portionSize,
      servingSize: servingSize ?? this.servingSize,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      imagePath: imagePath ?? this.imagePath,
      source: source ?? this.source,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      isEditable: isEditable ?? this.isEditable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// Calculate total macronutrients
  /// 
  /// Returns sum of protein, carbs, and fat
  double get totalMacros => protein + carbs + fat;

  /// Check if this food was created from AI scan
  bool get isFromAI => source == 'ai_scan';

  /// Check if this food was created manually
  bool get isManual => source == 'manual';

  /// Get formatted macro string
  /// 
  /// Example: "P: 12g • C: 20g • F: 5g"
  String get macroString {
    return 'P: ${protein.toStringAsFixed(1)}g • C: ${carbs.toStringAsFixed(1)}g • F: ${fat.toStringAsFixed(1)}g';
  }

  @override
  String toString() {
    return 'UserFoodModel(id: $id, name: $name, calories: $calories, source: $source, usageCount: $usageCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserFoodModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

