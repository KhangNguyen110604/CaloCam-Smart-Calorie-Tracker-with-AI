import 'package:uuid/uuid.dart';
import '../datasources/local/database_helper.dart';
import '../models/user_food_model.dart';

/// User Food Repository
/// 
/// Handles all operations related to custom user foods (món ăn của tôi)
/// Provides a clean API for CRUD operations on user-created foods
/// 
/// Features:
/// - Create new foods (manual or from AI)
/// - Read/search user foods
/// - Update existing foods
/// - Delete foods (with cascade to favorites)
/// - Track usage statistics
class UserFoodRepository {
  final DatabaseHelper _db;
  final Uuid _uuid = const Uuid();

  UserFoodRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  /// Create a new user food
  /// 
  /// Automatically generates ID and timestamps
  /// Returns the created model
  /// 
  /// Example:
  /// ```dart
  /// final food = await repo.createFood(
  ///   userId: 'user_1',
  ///   name: 'Phở gà nhà tôi',
  ///   calories: 150,
  ///   protein: 12,
  ///   carbs: 20,
  ///   fat: 5,
  ///   source: 'manual',
  /// );
  /// ```
  Future<UserFoodModel> createFood({
    required String userId,
    required String name,
    double portionSize = 100,
    double? servingSize,
    required double calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    String? imagePath,
    required String source, // 'manual' or 'ai_scan'
    double? aiConfidence,
  }) async {
    final food = UserFoodModel(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      portionSize: portionSize,
      servingSize: servingSize,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      imagePath: imagePath,
      source: source,
      aiConfidence: aiConfidence,
      isEditable: true,
      createdAt: DateTime.now(),
    );

    await _db.insertUserFood(food.toMap());
    return food;
  }

  /// Get all user foods
  /// 
  /// Returns list sorted by usage count (most used first)
  /// Optionally filter by search query
  Future<List<UserFoodModel>> getUserFoods(
    String userId, {
    String? searchQuery,
  }) async {
    final maps = await _db.getUserFoods(
      userId,
      searchQuery: searchQuery,
    );

    return maps.map((map) => UserFoodModel.fromMap(map)).toList();
  }

  /// Get a specific user food by ID
  Future<UserFoodModel?> getFoodById(String foodId) async {
    final map = await _db.getUserFood(foodId);
    return map != null ? UserFoodModel.fromMap(map) : null;
  }

  /// Update an existing food
  /// 
  /// Only works if food.isEditable = true
  /// Automatically updates `updated_at` timestamp
  Future<bool> updateFood(UserFoodModel food) async {
    final updated = food.copyWith(
      updatedAt: DateTime.now(),
    );

    final count = await _db.updateUserFood(updated.toMap());
    return count > 0;
  }

  /// Delete a food
  /// 
  /// Also removes from favorites automatically
  Future<bool> deleteFood(String foodId) async {
    final count = await _db.deleteUserFood(foodId);
    return count > 0;
  }

  /// Increment usage count when food is used in a meal
  /// 
  /// Updates usage_count and last_used_at
  Future<void> recordUsage(String foodId) async {
    await _db.incrementUserFoodUsage(foodId);
  }

  /// Get recently used foods
  /// 
  /// Returns foods sorted by last_used_at (most recent first)
  Future<List<UserFoodModel>> getRecentFoods(
    String userId, {
    int limit = 10,
  }) async {
    final maps = await _db.getUserFoods(
      userId,
      orderBy: 'last_used_at DESC',
    );

    return maps
        .take(limit)
        .map((map) => UserFoodModel.fromMap(map))
        .toList();
  }

  /// Get most used foods
  /// 
  /// Returns foods sorted by usage_count (highest first)
  Future<List<UserFoodModel>> getPopularFoods(
    String userId, {
    int limit = 10,
  }) async {
    final maps = await _db.getUserFoods(
      userId,
      orderBy: 'usage_count DESC',
    );

    return maps
        .take(limit)
        .map((map) => UserFoodModel.fromMap(map))
        .toList();
  }

  /// Get foods created from AI scans
  Future<List<UserFoodModel>> getAIFoods(String userId) async {
    final allFoods = await getUserFoods(userId);
    return allFoods.where((food) => food.source == 'ai_scan').toList();
  }

  /// Get foods created manually
  Future<List<UserFoodModel>> getManualFoods(String userId) async {
    final allFoods = await getUserFoods(userId);
    return allFoods.where((food) => food.source == 'manual').toList();
  }

  /// Get count of user foods
  Future<int> getFoodCount(String userId) async {
    final foods = await getUserFoods(userId);
    return foods.length;
  }

  /// Check if a food name already exists
  /// 
  /// Useful for preventing duplicates
  Future<bool> nameExists(String userId, String name) async {
    final foods = await getUserFoods(userId, searchQuery: name);
    return foods.any((food) => food.name.toLowerCase() == name.toLowerCase());
  }
}

