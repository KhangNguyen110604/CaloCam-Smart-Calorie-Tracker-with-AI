/// Favorite Food Model
/// 
/// Represents a food that user has marked as favorite (món yêu thích)
/// Can link to both built-in foods and custom user foods
/// 
/// Properties:
/// - [id]: Unique identifier (composite: userId_foodId_foodSource)
/// - [userId]: Owner of this favorite
/// - [foodId]: ID of the food (from foods or user_foods table)
/// - [foodSource]: Where the food comes from ('builtin' or 'custom')
/// - [addedAt]: When this was added to favorites
/// - [lastUsedAt]: When this favorite was last used in a meal
/// - [usageCount]: Number of times this favorite was used
/// 
/// The foodSource field determines which table to join:
/// - 'builtin' → joins with `foods` table
/// - 'custom' → joins with `user_foods` table
class FavoriteFoodModel {
  final String id;
  final String userId;
  final String foodId;
  final String foodSource; // 'builtin' or 'custom'
  final DateTime addedAt;
  final DateTime? lastUsedAt;
  final int usageCount;

  FavoriteFoodModel({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.foodSource,
    required this.addedAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  /// Convert model to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'food_id': foodId,
      'food_source': foodSource,
      'added_at': addedAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'usage_count': usageCount,
    };
  }

  /// Create model from database Map
  factory FavoriteFoodModel.fromMap(Map<String, dynamic> map) {
    return FavoriteFoodModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      foodId: map['food_id'] as String,
      foodSource: map['food_source'] as String,
      addedAt: DateTime.parse(map['added_at'] as String),
      lastUsedAt: map['last_used_at'] != null 
          ? DateTime.parse(map['last_used_at'] as String) 
          : null,
      usageCount: (map['usage_count'] as int?) ?? 0,
    );
  }

  /// Create a copy with modified fields
  FavoriteFoodModel copyWith({
    String? id,
    String? userId,
    String? foodId,
    String? foodSource,
    DateTime? addedAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return FavoriteFoodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      foodSource: foodSource ?? this.foodSource,
      addedAt: addedAt ?? this.addedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// Check if this is a built-in food favorite
  bool get isBuiltinFood => foodSource == 'builtin';

  /// Check if this is a custom food favorite
  bool get isCustomFood => foodSource == 'custom';

  /// Create composite ID from components
  /// 
  /// Format: {userId}_{foodId}_{foodSource}
  /// Example: "user_1_123_builtin"
  static String createId(String userId, String foodId, String foodSource) {
    return '${userId}_${foodId}_$foodSource';
  }

  /// Helper factory to create new favorite
  /// 
  /// Automatically generates composite ID
  factory FavoriteFoodModel.create({
    required String userId,
    required String foodId,
    required String foodSource,
  }) {
    return FavoriteFoodModel(
      id: createId(userId, foodId, foodSource),
      userId: userId,
      foodId: foodId,
      foodSource: foodSource,
      addedAt: DateTime.now(),
      usageCount: 0,
    );
  }

  @override
  String toString() {
    return 'FavoriteFoodModel(id: $id, foodId: $foodId, foodSource: $foodSource, usageCount: $usageCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteFoodModel && 
           other.userId == userId &&
           other.foodId == foodId &&
           other.foodSource == foodSource;
  }

  @override
  int get hashCode => Object.hash(userId, foodId, foodSource);
}

