import '../datasources/local/database_helper.dart';
import '../models/food_model.dart';
import '../models/unified_food_model.dart';
import 'user_food_repository.dart';
import 'favorite_repository.dart';

/// Food Repository (Unified)
/// 
/// Main repository for all food-related operations
/// Combines built-in foods and custom user foods into unified search results
/// 
/// Features:
/// - Unified search across both food sources
/// - Automatic favorite status integration
/// - Smart sorting (favorites first, then by usage)
/// - Caching for performance
/// 
/// Search Priority:
/// 1. User's favorite foods (both custom and built-in)
/// 2. User's custom foods (by usage count)
/// 3. Built-in foods
class FoodRepository {
  final DatabaseHelper _db;
  final UserFoodRepository _userFoodRepo;
  final FavoriteRepository _favoriteRepo;

  // Cache for performance
  Map<String, List<UnifiedFoodModel>>? _cachedFavorites;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  FoodRepository({
    DatabaseHelper? dbHelper,
    UserFoodRepository? userFoodRepo,
    FavoriteRepository? favoriteRepo,
  })  : _db = dbHelper ?? DatabaseHelper.instance,
        _userFoodRepo = userFoodRepo ?? UserFoodRepository(dbHelper: dbHelper),
        _favoriteRepo = favoriteRepo ?? FavoriteRepository(dbHelper: dbHelper);

  /// Search for foods across all sources
  /// 
  /// Returns unified list of foods from:
  /// - User's custom foods (món ăn của tôi)
  /// - Built-in foods (thư viện)
  /// 
  /// Results are sorted by:
  /// 1. Favorites first (by usage count)
  /// 2. Non-favorites by relevance
  /// 
  /// Example:
  /// ```dart
  /// final results = await repo.searchFoods(
  ///   userId: 'user_1',
  ///   query: 'phở',
  ///   limit: 20,
  /// );
  /// ```
  Future<List<UnifiedFoodModel>> searchFoods({
    required String userId,
    required String query,
    int limit = 50,
  }) async {
    final results = <UnifiedFoodModel>[];
    
    // Get favorites for status checking
    final favorites = await _getFavoritesWithCache(userId);
    final favoriteIds = favorites.map((f) => f.id).toSet();

    if (query.isEmpty) {
      // No search query - return favorites + recent
      return await _getDefaultSuggestions(userId, limit: limit);
    }

    // 1. Search custom user foods
    final customFoods = await _userFoodRepo.getUserFoods(
      userId,
      searchQuery: query,
    );

    for (final food in customFoods) {
      final isFav = favoriteIds.contains(food.id);
      final unified = UnifiedFoodModel.fromCustom(
        food,
        isFavorite: isFav,
        addedAt: isFav ? _getFavoriteAddedAt(favorites, food.id) : null,
      );
      results.add(unified);
    }

    // 2. Search built-in foods
    final builtInMaps = await _db.searchFoods(query);
    
    for (final map in builtInMaps) {
      final food = FoodModel.fromMap(map);
      final foodId = food.id.toString();
      final isFav = favoriteIds.contains(foodId);
      
      final unified = UnifiedFoodModel.fromBuiltIn(
        food,
        isFavorite: isFav,
        addedAt: isFav ? _getFavoriteAddedAt(favorites, foodId) : null,
      );
      results.add(unified);
    }

    // Sort: Favorites first (by usage), then non-favorites
    _sortFoodResults(results);

    return results.take(limit).toList();
  }

  /// Get default food suggestions (when no search query)
  /// 
  /// Returns:
  /// 1. Favorites (sorted by usage)
  /// 2. Recently used custom foods
  /// 3. Popular built-in foods
  Future<List<UnifiedFoodModel>> _getDefaultSuggestions(
    String userId, {
    int limit = 20,
  }) async {
    final results = <UnifiedFoodModel>[];

    // Get favorites
    final favorites = await _getFavoritesWithCache(userId);
    results.addAll(favorites);

    // If not enough, add recent custom foods
    if (results.length < limit) {
      final recentCustom = await _userFoodRepo.getRecentFoods(
        userId,
        limit: limit - results.length,
      );
      
      final favoriteIds = favorites.map((f) => f.id).toSet();
      
      for (final food in recentCustom) {
        if (!favoriteIds.contains(food.id)) {
          results.add(UnifiedFoodModel.fromCustom(food, isFavorite: false));
        }
      }
    }

    // If still not enough, add popular built-in foods
    if (results.length < limit) {
      final popularBuiltin = await _db.getAllFoods();
      final favoriteIds = favorites.map((f) => f.id).toSet();
      
      for (final map in popularBuiltin) {
        if (results.length >= limit) break;
        
        final food = FoodModel.fromMap(map);
        final foodId = food.id.toString();
        
        if (!favoriteIds.contains(foodId)) {
          results.add(UnifiedFoodModel.fromBuiltIn(food, isFavorite: false));
        }
      }
    }

    return results.take(limit).toList();
  }

  /// Get a specific food by ID and source
  /// 
  /// Returns UnifiedFoodModel with favorite status
  Future<UnifiedFoodModel?> getFood({
    required String userId,
    required String foodId,
    required String foodSource, // 'builtin' or 'custom'
  }) async {
    final isFav = await _favoriteRepo.isFavorite(userId, foodId, foodSource);

    if (foodSource == 'custom') {
      final food = await _userFoodRepo.getFoodById(foodId);
      if (food == null) return null;
      return UnifiedFoodModel.fromCustom(food, isFavorite: isFav);
    } else {
      // Built-in food
      final map = await _db.getFood(int.parse(foodId));
      if (map == null) return null;
      final food = FoodModel.fromMap(map);
      return UnifiedFoodModel.fromBuiltIn(food, isFavorite: isFav);
    }
  }

  /// Get favorites with caching
  Future<List<UnifiedFoodModel>> _getFavoritesWithCache(String userId) async {
    final now = DateTime.now();
    
    // Check cache validity
    if (_cachedFavorites != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!).compareTo(_cacheDuration) < 0 &&
        _cachedFavorites!.containsKey(userId)) {
      return _cachedFavorites![userId]!;
    }

    // Fetch fresh data
    final favorites = await _favoriteRepo.getFavoritesWithDetails(userId);
    
    // Update cache
    _cachedFavorites = {userId: favorites};
    _cacheTime = now;
    
    return favorites;
  }

  /// Clear favorites cache
  /// 
  /// Call this when favorites are added/removed
  void clearCache() {
    _cachedFavorites = null;
    _cacheTime = null;
  }

  /// Get suggestions for a specific meal type
  /// 
  /// Returns foods commonly used for this meal type
  /// Priority: Favorites for this meal > All favorites > Popular foods
  Future<List<UnifiedFoodModel>> getSuggestionsForMeal({
    required String userId,
    required String mealType,
    int limit = 10,
  }) async {
    // For now, return favorites
    // TODO: Track meal-type specific usage patterns
    final favorites = await _getFavoritesWithCache(userId);
    return favorites.take(limit).toList();
  }

  /// Get recently used foods (from meal entries)
  /// 
  /// Returns foods that were recently added to meals
  Future<List<UnifiedFoodModel>> getRecentlyUsedFoods({
    required String userId,
    int limit = 10,
  }) async {
    // TODO: Query meal_entries to find recently used foods
    // For now, return recent favorites
    return await _favoriteRepo.getRecentFavorites(userId, limit: limit);
  }

  /// Sort food results
  /// 
  /// Priority:
  /// 1. Favorites (by usage count, descending)
  /// 2. Non-favorites (by relevance)
  void _sortFoodResults(List<UnifiedFoodModel> results) {
    results.sort((a, b) {
      // Favorites first
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      
      // Both favorites or both non-favorites - sort by usage
      if (a.isFavorite && b.isFavorite) {
        return b.usageCount.compareTo(a.usageCount);
      }
      
      // Non-favorites - keep current order (relevance from search)
      return 0;
    });
  }

  /// Get added_at timestamp for a favorite
  DateTime? _getFavoriteAddedAt(List<UnifiedFoodModel> favorites, String foodId) {
    try {
      return favorites.firstWhere((f) => f.id == foodId).addedAt;
    } catch (e) {
      return null;
    }
  }

  /// Get food statistics
  /// 
  /// Returns overview of all foods available to user
  Future<Map<String, int>> getStats(String userId) async {
    final customCount = await _userFoodRepo.getFoodCount(userId);
    final favoriteStats = await _favoriteRepo.getStats(userId);
    
    // Get total built-in foods count
    final builtinMaps = await _db.getAllFoods();
    final builtinCount = builtinMaps.length;
    
    return {
      'total_builtin': builtinCount,
      'total_custom': customCount,
      'total_favorites': favoriteStats['total'] ?? 0,
      'custom_favorites': favoriteStats['custom'] ?? 0,
      'builtin_favorites': favoriteStats['builtin'] ?? 0,
    };
  }
}

