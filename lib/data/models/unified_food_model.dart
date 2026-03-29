import 'food_model.dart';
import 'user_food_model.dart';

/// Unified Food Model
/// 
/// A wrapper that can represent both built-in foods and custom user foods
/// Used in UI to display mixed lists without type checking everywhere
/// 
/// This class provides a unified interface for:
/// - Built-in foods (from foods table - read-only)
/// - Custom foods (from user_foods table - editable)
/// 
/// Usage:
/// ```dart
/// // From built-in food
/// final unified = UnifiedFoodModel.fromBuiltIn(foodModel, isFavorite: true);
/// 
/// // From custom food
/// final unified = UnifiedFoodModel.fromCustom(userFoodModel, isFavorite: false);
/// 
/// // Check type
/// if (unified.isCustom && unified.isEditable) {
///   // Show edit button
/// }
/// ```
class UnifiedFoodModel {
  final String id;
  final String name;
  final double portionSize;
  final double? servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imagePath;
  final String source; // 'builtin', 'manual', or 'ai_scan'
  final bool isEditable;
  final bool isFavorite;
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime? addedAt; // When added to favorites

  // Original models (keep for type-specific operations)
  final FoodModel? _builtinFood;
  final UserFoodModel? _customFood;

  UnifiedFoodModel._({
    required this.id,
    required this.name,
    required this.portionSize,
    this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imagePath,
    required this.source,
    required this.isEditable,
    required this.isFavorite,
    required this.usageCount,
    this.lastUsedAt,
    this.addedAt,
    FoodModel? builtinFood,
    UserFoodModel? customFood,
  })  : _builtinFood = builtinFood,
        _customFood = customFood;

  /// Create from built-in food
  /// 
  /// Built-in foods are always read-only (isEditable = false)
  factory UnifiedFoodModel.fromBuiltIn(
    FoodModel food, {
    required bool isFavorite,
    int usageCount = 0,
    DateTime? lastUsedAt,
    DateTime? addedAt,
  }) {
    return UnifiedFoodModel._(
      id: food.id.toString(),
      name: food.name,
      portionSize: 100, // Built-in foods don't have explicit portion_size
      servingSize: food.servingSize,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      imagePath: food.imageUrl,
      source: 'builtin',
      isEditable: false, // Built-in foods cannot be edited
      isFavorite: isFavorite,
      usageCount: usageCount,
      lastUsedAt: lastUsedAt,
      addedAt: addedAt,
      builtinFood: food,
    );
  }

  /// Create from custom user food
  /// 
  /// Custom foods are always editable (isEditable = true)
  factory UnifiedFoodModel.fromCustom(
    UserFoodModel food, {
    required bool isFavorite,
    DateTime? addedAt,
  }) {
    return UnifiedFoodModel._(
      id: food.id,
      name: food.name,
      portionSize: food.portionSize,
      servingSize: food.servingSize,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      imagePath: food.imagePath,
      source: food.source, // 'manual' or 'ai_scan'
      isEditable: food.isEditable,
      isFavorite: isFavorite,
      usageCount: food.usageCount,
      lastUsedAt: food.lastUsedAt,
      addedAt: addedAt,
      customFood: food,
    );
  }

  /// Create from database map with full details
  /// 
  /// Used when loading favorites with joined data
  /// Map should include 'source' field to determine type
  factory UnifiedFoodModel.fromMap(Map<String, dynamic> map) {
    final source = map['source'] as String;

    return UnifiedFoodModel._(
      id: map['food_id']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name'] as String,
      portionSize: _parseDouble(map['portion_size']) ?? 100,
      servingSize: _parseDouble(map['serving_size']),
      calories: _parseDouble(map['calories']) ?? 0,
      protein: _parseDouble(map['protein']) ?? 0,
      carbs: _parseDouble(map['carbs']) ?? 0,
      fat: _parseDouble(map['fat']) ?? 0,
      imagePath: map['image_url'] as String? ?? map['image_path'] as String?,
      source: source,
      isEditable: (map['is_editable'] as int?) == 1,
      isFavorite: true, // Assume true if from favorites query
      usageCount: _parseInt(map['usage_count']) ?? 0,
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.parse(map['last_used_at'] as String)
          : null,
      addedAt: map['added_at'] != null
          ? DateTime.parse(map['added_at'] as String)
          : null,
    );
  }

  /// Helper: Parse double from dynamic value (handles both num and String)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper: Parse int from dynamic value (handles both num and String)
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Check if this is a built-in food
  bool get isBuiltin => source == 'builtin';

  /// Check if this is a custom user food
  bool get isCustom => source == 'manual' || source == 'ai_scan';

  /// Check if this was created from AI scan
  bool get isFromAI => source == 'ai_scan';

  /// Check if this was created manually
  bool get isManual => source == 'manual';

  /// Get the food source for database operations
  /// 
  /// Returns 'builtin' or 'custom'
  String get foodSource => isBuiltin ? 'builtin' : 'custom';

  /// Get formatted macro string
  /// 
  /// Example: "P: 12g • C: 20g • F: 5g"
  String get macroString {
    return 'P: ${protein.toStringAsFixed(1)}g • C: ${carbs.toStringAsFixed(1)}g • F: ${fat.toStringAsFixed(1)}g';
  }

  /// Get formatted calories string
  /// 
  /// Example: "150 kcal"
  String get calorieString => '${calories.toStringAsFixed(0)} kcal';

  /// Get source badge text
  /// 
  /// Returns user-friendly text for displaying source
  String get sourceBadge {
    switch (source) {
      case 'builtin':
        return 'Thư viện';
      case 'manual':
        return 'Của tôi';
      case 'ai_scan':
        return 'Từ AI';
      default:
        return '';
    }
  }

  /// Get original built-in food model (if applicable)
  FoodModel? get asBuiltinFood => _builtinFood;

  /// Get original custom food model (if applicable)
  UserFoodModel? get asCustomFood => _customFood;

  /// Create a copy with modified fields
  UnifiedFoodModel copyWith({
    bool? isFavorite,
    int? usageCount,
    DateTime? lastUsedAt,
    DateTime? addedAt,
  }) {
    return UnifiedFoodModel._(
      id: id,
      name: name,
      portionSize: portionSize,
      servingSize: servingSize,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      imagePath: imagePath,
      source: source,
      isEditable: isEditable,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      addedAt: addedAt ?? this.addedAt,
      builtinFood: _builtinFood,
      customFood: _customFood,
    );
  }

  @override
  String toString() {
    return 'UnifiedFoodModel(id: $id, name: $name, source: $source, '
           'isFavorite: $isFavorite, isEditable: $isEditable, usageCount: $usageCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedFoodModel && 
           other.id == id && 
           other.source == source;
  }

  @override
  int get hashCode => Object.hash(id, source);
}

