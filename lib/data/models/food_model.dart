/// Food Model - Represents a food item in the catalog
class FoodModel {
  final int? id;
  final String name;
  final String nameEn; // Added for English name
  final String category;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String portionSize;
  final double servingSize; // Added for numeric serving size
  final String? imageUrl;
  final String? description;
  final String? ingredients;
  final bool isFavorite;
  final DateTime createdAt;

  FoodModel({
    this.id,
    required this.name,
    this.nameEn = '',
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portionSize,
    this.servingSize = 100.0,
    this.imageUrl,
    this.description,
    this.ingredients,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert from database map
  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      nameEn: map['name_en'] as String? ?? '',
      category: map['category'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      portionSize: map['portion_size'] as String,
      servingSize: (map['serving_size'] as num?)?.toDouble() ?? 100.0,
      imageUrl: map['image_url'] as String?,
      description: map['description'] as String?,
      ingredients: map['ingredients'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'portion_size': portionSize,
      'image_url': imageUrl,
      'description': description,
      'ingredients': ingredients,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  FoodModel copyWith({
    int? id,
    String? name,
    String? nameEn,
    String? category,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? portionSize,
    double? servingSize,
    String? imageUrl,
    String? description,
    String? ingredients,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      portionSize: portionSize ?? this.portionSize,
      servingSize: servingSize ?? this.servingSize,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'FoodModel(id: $id, name: $name, calories: $calories kcal/$portionSize)';
  }
}
