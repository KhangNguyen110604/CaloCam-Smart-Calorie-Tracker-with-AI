import '../datasources/local/database_helper.dart';
import '../models/favorite_food_model.dart';
import '../models/unified_food_model.dart';

/// Favorite Repository
/// 
/// Handles all operations related to favorite foods (món yêu thích)
/// Manages favorites for both built-in and custom user foods
/// 
/// Features:
/// - Add/remove favorites
/// - Check favorite status
/// - Get favorites list with full details
/// - Track usage statistics
/// - Get statistics
class FavoriteRepository {
  final DatabaseHelper _db;

  FavoriteRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  /// Add a food to favorites
  /// 
  /// [foodSource] must be 'builtin' or 'custom'
  /// Returns true if added, false if already exists
  /// 
  /// Example:
  /// ```dart
  /// // Add built-in food
  /// await repo.addFavorite('user_1', '123', 'builtin');
  /// 
  /// // Add custom food
  /// await repo.addFavorite('user_1', 'uuid-abc', 'custom');
  /// ```
  Future<bool> addFavorite(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    // Check if already favorited
    final exists = await isFavorite(userId, foodId, foodSource);
    if (exists) return false;

    final count = await _db.addFavorite(userId, foodId, foodSource);
    return count > 0;
  }

  /// Remove a food from favorites
  Future<bool> removeFavorite(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    final count = await _db.removeFavorite(userId, foodId, foodSource);
    return count > 0;
  }

  /// Toggle favorite status
  /// 
  /// Adds if not favorited, removes if already favorited
  /// Returns new status (true = favorited, false = not favorited)
  Future<bool> toggleFavorite(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    final isCurrentlyFavorite = await isFavorite(userId, foodId, foodSource);
    
    if (isCurrentlyFavorite) {
      await removeFavorite(userId, foodId, foodSource);
      return false;
    } else {
      await addFavorite(userId, foodId, foodSource);
      return true;
    }
  }

  /// Check if a food is favorited
  Future<bool> isFavorite(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    return await _db.isFavorite(userId, foodId, foodSource);
  }

  /// Get all favorites (just the favorite records)
  /// 
  /// Returns FavoriteFoodModel list (doesn't include food details)
  /// Use [getFavoritesWithDetails] to get full food information
  Future<List<FavoriteFoodModel>> getFavorites(
    String userId, {
    String? foodSource,
  }) async {
    final maps = await _db.getFavorites(
      userId,
      foodSource: foodSource,
    );

    return maps.map((map) => FavoriteFoodModel.fromMap(map)).toList();
  }

  /// Get favorites with full food details
  /// 
  /// Returns UnifiedFoodModel list with all nutrition information
  /// Includes both built-in and custom foods in one list
  /// Sorted by usage_count (most used first)
  Future<List<UnifiedFoodModel>> getFavoritesWithDetails(
    String userId,
  ) async {
    final maps = await _db.getFavoriteFoodsWithDetails(userId);
    return maps.map((map) => UnifiedFoodModel.fromMap(map)).toList();
  }

  /// Get only built-in food favorites with details
  Future<List<UnifiedFoodModel>> getBuiltinFavorites(String userId) async {
    final all = await getFavoritesWithDetails(userId);
    return all.where((food) => food.isBuiltin).toList();
  }

  /// Get only custom food favorites with details
  Future<List<UnifiedFoodModel>> getCustomFavorites(String userId) async {
    final all = await getFavoritesWithDetails(userId);
    return all.where((food) => food.isCustom).toList();
  }

  /// Record usage when a favorite is used in a meal
  /// 
  /// Updates usage_count and last_used_at
  Future<void> recordUsage(
    String userId,
    String foodId,
    String foodSource,
  ) async {
    await _db.incrementFavoriteUsage(userId, foodId, foodSource);
  }

  /// Get top N most used favorites
  Future<List<UnifiedFoodModel>> getTopFavorites(
    String userId, {
    int limit = 5,
  }) async {
    final all = await getFavoritesWithDetails(userId);
    return all.take(limit).toList(); // Already sorted by usage_count
  }

  /// Get recently used favorites
  /// 
  /// Returns favorites sorted by last_used_at (most recent first)
  Future<List<UnifiedFoodModel>> getRecentFavorites(
    String userId, {
    int limit = 10,
  }) async {
    final all = await getFavoritesWithDetails(userId);
    
    // Filter out items without last_used_at and sort
    final withUsage = all.where((f) => f.lastUsedAt != null).toList();
    withUsage.sort((a, b) {
      final aTime = a.lastUsedAt!;
      final bTime = b.lastUsedAt!;
      return bTime.compareTo(aTime); // DESC
    });
    
    return withUsage.take(limit).toList();
  }

  /// Get favorite statistics
  /// 
  /// Returns:
  /// - total: Total number of favorites
  /// - custom: Number of custom food favorites
  /// - builtin: Number of built-in food favorites
  Future<Map<String, int>> getStats(String userId) async {
    return await _db.getFavoriteStats(userId);
  }

  /// Get favorite count
  Future<int> getFavoriteCount(String userId) async {
    final stats = await getStats(userId);
    return stats['total'] ?? 0;
  }

  /// Check if user has any favorites
  Future<bool> hasFavorites(String userId) async {
    final count = await getFavoriteCount(userId);
    return count > 0;
  }

  /// Get suggestions based on meal type and time
  /// 
  /// Returns favorites commonly used for specific meal types
  /// Uses usage patterns to provide smart suggestions
  Future<List<UnifiedFoodModel>> getSuggestionsForMeal(
    String userId,
    String mealType, {
    int limit = 5,
  }) async {
    // TODO: Implement meal-type specific suggestions
    // For now, return top favorites
    // In future, can track which favorites are used for which meal types
    return await getTopFavorites(userId, limit: limit);
  }
}

