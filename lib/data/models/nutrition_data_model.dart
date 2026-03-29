import 'dart:convert';

/// Nutrition Data Model
/// 
/// Represents nutrition information for a food item.
/// Used for both local database and API responses.
/// 
/// All nutrition values are per 100g for standardization.
/// This allows easy calculation for any portion size.
/// 
/// Example usage:
/// ```dart
/// final nutrition = NutritionDataModel(
///   foodName: 'pho bo',
///   foodNameVi: 'Phở bò',
///   caloriesPer100g: 70.0,
///   proteinPer100g: 5.0,
///   carbsPer100g: 10.0,
///   fatPer100g: 1.5,
/// );
/// 
/// // Calculate for 500g portion
/// final result = nutrition.calculateForPortion(500);
/// print('Calories: ${result['calories']} kcal'); // 350 kcal
/// ```
class NutritionDataModel {
  final int? id;
  final String foodName;           // Normalized name (lowercase, no accents)
  final String? foodNameEn;        // English name
  final String? foodNameVi;        // Vietnamese name
  
  // Nutrition per 100g (standardized)
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  
  // Serving sizes (common portions)
  final List<ServingSize>? servingSizes;
  
  // Metadata
  final String source;             // 'manual', 'fatsecret', 'usda', 'user'
  final String? category;          // 'vietnamese', 'western', 'asian', etc.
  final bool isVerified;           // Data verified by admin/expert
  final int usageCount;            // How many times used (for ranking)
  final DateTime? lastUsed;        // Last usage timestamp
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NutritionDataModel({
    this.id,
    required this.foodName,
    this.foodNameEn,
    this.foodNameVi,
    required this.caloriesPer100g,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.fiberPer100g,
    this.servingSizes,
    this.source = 'manual',
    this.category,
    this.isVerified = false,
    this.usageCount = 0,
    this.lastUsed,
    this.createdAt,
    this.updatedAt,
  });

  /// Calculate nutrition for a specific portion
  /// 
  /// [grams]: Weight in grams
  /// Returns: Map with calculated nutrition values
  /// 
  /// Example:
  /// ```dart
  /// final result = nutrition.calculateForPortion(500); // 500g
  /// print('Calories: ${result['calories']}');
  /// print('Protein: ${result['protein']}g');
  /// ```
  Map<String, double> calculateForPortion(double grams) {
    final multiplier = grams / 100.0;
    return {
      'calories': caloriesPer100g * multiplier,
      'protein': proteinPer100g * multiplier,
      'carbs': carbsPer100g * multiplier,
      'fat': fatPer100g * multiplier,
      'fiber': (fiberPer100g ?? 0) * multiplier,
    };
  }

  /// Convert to Map (for database insert)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_name': foodName,
      'food_name_en': foodNameEn,
      'food_name_vi': foodNameVi,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'fiber_per_100g': fiberPer100g,
      'serving_sizes': servingSizes != null 
          ? jsonEncode(servingSizes!.map((s) => s.toJson()).toList())
          : null,
      'source': source,
      'category': category,
      'is_verified': isVerified ? 1 : 0,
      'usage_count': usageCount,
      'last_used': lastUsed?.toIso8601String(),
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Create from Map (from database query)
  factory NutritionDataModel.fromMap(Map<String, dynamic> map) {
    return NutritionDataModel(
      id: map['id'] as int?,
      foodName: map['food_name'] as String,
      foodNameEn: map['food_name_en'] as String?,
      foodNameVi: map['food_name_vi'] as String?,
      caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
      proteinPer100g: (map['protein_per_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (map['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (map['fat_per_100g'] as num?)?.toDouble() ?? 0,
      fiberPer100g: (map['fiber_per_100g'] as num?)?.toDouble(),
      servingSizes: map['serving_sizes'] != null
          ? (jsonDecode(map['serving_sizes'] as String) as List)
              .map((s) => ServingSize.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      source: map['source'] as String? ?? 'manual',
      category: map['category'] as String?,
      isVerified: (map['is_verified'] as int?) == 1,
      usageCount: (map['usage_count'] as int?) ?? 0,
      lastUsed: map['last_used'] != null 
          ? DateTime.parse(map['last_used'] as String)
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Create a copy with updated fields
  NutritionDataModel copyWith({
    int? id,
    String? foodName,
    String? foodNameEn,
    String? foodNameVi,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? fiberPer100g,
    List<ServingSize>? servingSizes,
    String? source,
    String? category,
    bool? isVerified,
    int? usageCount,
    DateTime? lastUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NutritionDataModel(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      foodNameEn: foodNameEn ?? this.foodNameEn,
      foodNameVi: foodNameVi ?? this.foodNameVi,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      servingSizes: servingSizes ?? this.servingSizes,
      source: source ?? this.source,
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'NutritionDataModel(id: $id, foodName: $foodName, calories: $caloriesPer100g kcal/100g)';
  }
}

/// Serving Size Model
/// 
/// Represents a common serving size for a food item.
/// Helps users select portions in familiar terms instead of grams.
/// 
/// Example:
/// - "Tô lớn" = 500g
/// - "Bát nhỏ" = 300g
/// - "1 cái" = 50g
/// 
/// Usage:
/// ```dart
/// final serving = ServingSize(name: 'Tô lớn', grams: 500);
/// ```
class ServingSize {
  final String name;      // Display name: "Tô lớn", "Bát nhỏ", "1 cái"
  final double grams;     // Weight in grams
  
  ServingSize({
    required this.name,
    required this.grams,
  });

  /// Convert to JSON (for database storage)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grams': grams,
    };
  }

  /// Create from JSON (from database)
  factory ServingSize.fromJson(Map<String, dynamic> json) {
    return ServingSize(
      name: json['name'] as String,
      grams: (json['grams'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return '$name ($grams g)';
  }
}

