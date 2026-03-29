import 'package:flutter/foundation.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/repositories/user_food_repository.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../data/models/unified_food_model.dart';
import '../../data/models/user_food_model.dart';
import '../../data/models/favorite_food_model.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import 'sync_provider.dart';

/// Food Provider
/// 
/// State management for food-related operations
/// Manages:
/// - Food search (unified across built-in + custom)
/// - Custom food CRUD
/// - Favorite toggling
/// - Loading states
/// 
/// Usage:
/// ```dart
/// final provider = Provider.of<FoodProvider>(context);
/// await provider.searchFoods('phở');
/// 
/// if (provider.isLoading) {
///   return CircularProgressIndicator();
/// }
/// 
/// return ListView(children: provider.searchResults.map(...));
/// ```
class FoodProvider with ChangeNotifier {
  // Repositories
  final FoodRepository _foodRepo;
  final UserFoodRepository _userFoodRepo;
  final FavoriteRepository _favoriteRepo;
  final SyncProvider? _syncProvider;

  // Current user ID (should be set on login)
  // NOTE: This is the LOCAL user ID (integer), not Firebase UID
  int? _userId;

  // State
  List<UnifiedFoodModel> _searchResults = [];
  List<UserFoodModel> _myFoods = [];
  List<UnifiedFoodModel> _favorites = [];
  
  bool _isLoading = false;
  String? _error;
  String _lastQuery = '';

  FoodProvider({
    FoodRepository? foodRepo,
    UserFoodRepository? userFoodRepo,
    FavoriteRepository? favoriteRepo,
    SyncProvider? syncProvider,
  })  : _foodRepo = foodRepo ?? FoodRepository(),
        _userFoodRepo = userFoodRepo ?? UserFoodRepository(),
        _favoriteRepo = favoriteRepo ?? FavoriteRepository(),
        _syncProvider = syncProvider;

  // ==================== GETTERS ====================

  List<UnifiedFoodModel> get searchResults => _searchResults;
  List<UserFoodModel> get myFoods => _myFoods;
  List<UnifiedFoodModel> get favorites => _favorites;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get lastQuery => _lastQuery;
  int? get userId => _userId;

  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get hasMyFoods => _myFoods.isNotEmpty;
  bool get hasFavorites => _favorites.isNotEmpty;

  // ==================== USER ID ====================

  /// Get current user ID from SharedPreferences
  /// 
  /// Returns the LOCAL user ID (integer) from SharedPreferences
  Future<int?> _getUserId() async {
    if (_userId != null) return _userId;
    _userId = await SharedPrefsHelper.getUserId();
    return _userId;
  }

  /// Get Firebase UID for Firestore sync
  /// 
  /// Returns Firebase UID from SharedPreferences
  Future<String?> _getFirebaseUid() async {
    return await SharedPrefsHelper.getFirebaseUid();
  }

  /// Clear user ID (on logout)
  void clearUserId() {
    _userId = null;
    _searchResults = [];
    _myFoods = [];
    _favorites = [];
    _foodRepo.clearCache();
    notifyListeners();
  }

  // ==================== SEARCH ====================

  /// Search for foods across all sources
  /// 
  /// Searches both built-in foods and user's custom foods
  /// Updates [searchResults] with unified list
  Future<void> searchFoods(String query, {int limit = 50}) async {
    _lastQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for searchFoods');
        _searchResults = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _searchResults = await _foodRepo.searchFoods(
        userId: userId.toString(),
        query: query,
        limit: limit,
      );
      _error = null;
    } catch (e) {
      _error = 'Lỗi tìm kiếm: $e';
      _searchResults = [];
      debugPrint('❌ Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _lastQuery = '';
    _error = null;
    notifyListeners();
  }

  /// Get default suggestions (no search query)
  Future<void> loadDefaultSuggestions({int limit = 20}) async {
    return searchFoods('', limit: limit);
  }

  /// NEW: Load suggestions for a specific meal
  /// 
  /// Shows favorites first, then fills with popular foods
  /// This is used in AddMealScreen's "Gợi ý" tab
  Future<void> loadSuggestionsForMeal(String mealType, {int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for loadSuggestionsForMeal');
        _searchResults = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final suggestions = await _foodRepo.getSuggestionsForMeal(
        userId: userId.toString(),
        mealType: mealType,
        limit: limit,
      );
      _searchResults = suggestions; // Use searchResults as suggestions storage
      _error = null;
    } catch (e) {
      _error = 'Lỗi tải gợi ý: $e';
      _searchResults = [];
      debugPrint('❌ Load suggestions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NEW: Getter for suggestions (alias for searchResults)
  List<UnifiedFoodModel> get suggestions => _searchResults;

  // ==================== MY FOODS ====================

  /// Load user's custom foods
  Future<void> loadMyFoods({String? searchQuery}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for loadMyFoods');
        _myFoods = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _myFoods = await _userFoodRepo.getUserFoods(
        userId.toString(),
        searchQuery: searchQuery,
      );
      _error = null;
      debugPrint('✅ [FoodProvider] Loaded ${_myFoods.length} user foods for user $userId');
    } catch (e) {
      _error = 'Lỗi tải món: $e';
      _myFoods = [];
      debugPrint('❌ Load my foods error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new custom food
  Future<UserFoodModel?> createFood({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for createFood');
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final food = await _userFoodRepo.createFood(
        userId: userId.toString(),
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
      );

      // Sync to cloud (real-time)
      // IMPORTANT: Use Firebase UID for Firestore sync
      if (_syncProvider != null) {
        final firebaseUid = await _getFirebaseUid();
        if (firebaseUid != null) {
          await _syncProvider.syncUserFoodToCloud(firebaseUid, food);
          debugPrint('☁️ [FoodProvider] User food synced to cloud');
        }
      }

      // Reload my foods
      await loadMyFoods();
      
      return food;
    } catch (e) {
      _error = 'Lỗi tạo món: $e';
      debugPrint('❌ Create food error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Update an existing custom food
  Future<bool> updateFood(UserFoodModel food) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _userFoodRepo.updateFood(food);
      
      if (success) {
        // Sync to cloud (real-time)
        // IMPORTANT: Use Firebase UID for Firestore sync
        if (_syncProvider != null) {
          final firebaseUid = await _getFirebaseUid();
          if (firebaseUid != null) {
            await _syncProvider.syncUserFoodToCloud(firebaseUid, food);
            debugPrint('☁️ [FoodProvider] User food update synced to cloud');
          }
        }
        
        // Reload my foods
        await loadMyFoods();
      }
      
      return success;
    } catch (e) {
      _error = 'Lỗi cập nhật món: $e';
      debugPrint('❌ Update food error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a custom food
  Future<bool> deleteFood(String foodId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _userFoodRepo.deleteFood(foodId);
      
      if (success) {
        // Sync deletion to cloud (real-time)
        if (_syncProvider != null) {
          final firebaseUid = await _getFirebaseUid();
          if (firebaseUid != null) {
            await _syncProvider.deleteUserFoodFromCloud(firebaseUid, foodId);
            debugPrint('☁️ [FoodProvider] User food deletion synced to cloud');
          }
        }
        
        // Reload my foods and favorites
        await loadMyFoods();
        await loadFavorites();
      }
      
      return success;
    } catch (e) {
      _error = 'Lỗi xóa món: $e';
      debugPrint('❌ Delete food error: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================== FAVORITES ====================

  /// Load favorites with full details
  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for loadFavorites');
        _favorites = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _favorites = await _favoriteRepo.getFavoritesWithDetails(userId.toString());
      
      // Clear food repo cache to get updated favorite status
      _foodRepo.clearCache();
      
      _error = null;
      debugPrint('✅ [FoodProvider] Loaded ${_favorites.length} favorites for user $userId');
    } catch (e) {
      _error = 'Lỗi tải yêu thích: $e';
      _favorites = [];
      debugPrint('❌ Load favorites error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle favorite status for a food
  /// 
  /// Returns new status (true = now favorited, false = now unfavorited)
  Future<bool> toggleFavorite(String foodId, String foodSource) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for toggleFavorite');
        return false;
      }

      final newStatus = await _favoriteRepo.toggleFavorite(
        userId.toString(),
        foodId,
        foodSource,
      );

      // Sync to cloud (real-time)
      if (_syncProvider != null) {
        if (newStatus) {
          // Added to favorites - sync to cloud
          // Create a FavoriteFoodModel to sync
          final favorite = FavoriteFoodModel(
            id: '${foodId}_$foodSource',
            userId: userId.toString(),
            foodId: foodId,
            foodSource: foodSource,
            addedAt: DateTime.now(),
          );
          // IMPORTANT: Use Firebase UID for Firestore sync
          final firebaseUid = await _getFirebaseUid();
          if (firebaseUid != null) {
            await _syncProvider.syncFavoriteToCloud(firebaseUid, favorite);
            debugPrint('☁️ [FoodProvider] Favorite synced to cloud');
          }
        } else {
          // Removed from favorites - delete from cloud
          // IMPORTANT: Use Firebase UID for Firestore sync
          final firebaseUid = await _getFirebaseUid();
          if (firebaseUid != null) {
            await _syncProvider.deleteFavoriteFromCloud(firebaseUid, foodId, foodSource);
            debugPrint('☁️ [FoodProvider] Favorite deletion synced to cloud');
          }
        }
      }

      // Update search results if any
      _updateSearchResultFavoriteStatus(foodId, foodSource, newStatus);
      
      // Reload favorites
      await loadFavorites();
      
      return newStatus;
    } catch (e) {
      _error = 'Lỗi cập nhật yêu thích: $e';
      debugPrint('❌ Toggle favorite error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update favorite status in search results without reloading
  void _updateSearchResultFavoriteStatus(
    String foodId,
    String foodSource,
    bool newStatus,
  ) {
    for (int i = 0; i < _searchResults.length; i++) {
      final food = _searchResults[i];
      if (food.id == foodId && food.foodSource == foodSource) {
        _searchResults[i] = food.copyWith(isFavorite: newStatus);
        break;
      }
    }
    notifyListeners();
  }

  /// Record usage when food is added to meal
  Future<void> recordFoodUsage(String foodId, String foodSource) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for recordFoodUsage');
        return;
      }

      // Record in favorite if favorited
      final isFav = await _favoriteRepo.isFavorite(userId.toString(), foodId, foodSource);
      if (isFav) {
        await _favoriteRepo.recordUsage(userId.toString(), foodId, foodSource);
      }

      // Record in user food if custom
      if (foodSource == 'custom') {
        await _userFoodRepo.recordUsage(foodId);
      }

      // Clear cache to get updated usage counts
      _foodRepo.clearCache();
    } catch (e) {
      debugPrint('❌ Record usage error: $e');
    }
  }

  // ==================== SUGGESTIONS ====================

  /// Get food suggestions for a meal
  Future<List<UnifiedFoodModel>> getSuggestionsForMeal(
    String mealType, {
    int limit = 10,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for getSuggestionsForMeal');
        return [];
      }

      return await _foodRepo.getSuggestionsForMeal(
        userId: userId.toString(),
        mealType: mealType,
        limit: limit,
      );
    } catch (e) {
      debugPrint('❌ Get suggestions error: $e');
      return [];
    }
  }

  // ==================== STATISTICS ====================

  /// Get food statistics
  Future<Map<String, int>> getStats() async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('⚠️ [FoodProvider] No userId found for getStats');
        return {};
      }

      return await _foodRepo.getStats(userId.toString());
    } catch (e) {
      debugPrint('❌ Get stats error: $e');
      return {};
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== SYNC ====================

  /// Refresh data from sync (called by SyncProvider when remote changes detected)
  Future<void> refreshFromSync() async {
    try {
      debugPrint('🔄 [FoodProvider] Refreshing from sync');
      await loadMyFoods();
      await loadFavorites();
      // Re-run last search if any
      if (_lastQuery.isNotEmpty) {
        await searchFoods(_lastQuery);
      }
    } catch (e) {
      debugPrint('❌ [FoodProvider] Error refreshing from sync: $e');
    }
  }
}

