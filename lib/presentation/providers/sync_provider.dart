import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart'; // ✅ Import for ConflictAlgorithm
import 'dart:async';
import '../../data/services/firestore_service.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/repositories/user_food_repository.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../data/models/meal_entry_model.dart';

/// Sync Provider
/// 
/// Manages data synchronization between local SQLite and Firestore.
/// 
/// **Features:**
/// - Manual sync (user-initiated)
/// - Auto-sync on app launch
/// - Auto-sync on data changes
/// - Sync status tracking
/// - Error handling
/// 
/// **Usage:**
/// ```dart
/// final syncProvider = Provider.of<SyncProvider>(context);
/// 
/// // Manually sync
/// await syncProvider.syncToCloud(userId);
/// 
/// // Check sync status
/// if (syncProvider.isSyncing) {
///   // Show loading indicator
/// }
/// ```
class SyncProvider extends ChangeNotifier {
  // ==================== SERVICES ====================
  
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final UserFoodRepository _userFoodRepo = UserFoodRepository();
  final FavoriteRepository _favoriteRepo = FavoriteRepository();

  // ==================== STATE ====================
  
  /// Is currently syncing
  bool _isSyncing = false;

  /// Last sync time
  DateTime? _lastSyncTime;

  /// Sync error message
  String? _syncError;

  /// Sync success message
  String? _syncSuccess;

  // ==================== GETTERS ====================
  
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;
  String? get syncSuccess => _syncSuccess;
  
  /// Get human-readable last sync time
  String get lastSyncTimeFormatted {
    if (_lastSyncTime == null) return 'Chưa đồng bộ';
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  // ==================== PRIVATE HELPERS ====================
  
  void _setLoading(bool loading) {
    _isSyncing = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _syncError = error;
    _syncSuccess = null;
    notifyListeners();
  }

  void _setSuccess(String? message) {
    _syncSuccess = message;
    _syncError = null;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _syncError = null;
    _syncSuccess = null;
    notifyListeners();
  }

  // ==================== SYNC OPERATIONS ====================
  
  /// Sync local data to Firestore
  /// 
  /// Uploads all local data (meals, user foods, favorites) to cloud.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> syncToCloud(String userId) async {
    try {
      _setLoading(true);
      clearMessages();

      debugPrint('☁️ [SyncProvider] Starting sync to cloud');

      // 1. Get all local data
      final mealMaps = await _databaseHelper.getAllMealEntriesForSync();
      final meals = mealMaps.map((map) => MealEntryModel.fromMap(map)).toList();
      final userFoods = await _userFoodRepo.getUserFoods(userId);
      final favorites = await _favoriteRepo.getFavorites(userId);

      debugPrint('📦 [SyncProvider] Local data:');
      debugPrint('  - Meals: ${meals.length}');
      debugPrint('  - User Foods: ${userFoods.length}');
      debugPrint('  - Favorites: ${favorites.length}');

      // 2. Sync to Firestore
      await _firestoreService.fullSync(
        userId: userId,
        meals: meals,
        userFoods: userFoods,
        favorites: favorites,
      );

      _setSuccess('Đồng bộ thành công! ✅');
      debugPrint('✅ [SyncProvider] Sync to cloud completed');
      
      return true;
    } catch (e) {
      _setError('Lỗi đồng bộ: ${e.toString()}');
      debugPrint('❌ [SyncProvider] Sync to cloud error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sync Firestore data to local database
  /// 
  /// Downloads all cloud data and merges with local database.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> syncFromCloud(String userId) async {
    try {
      _setLoading(true);
      clearMessages();

      debugPrint('📥 [SyncProvider] Starting sync from cloud');

      // 1. Get all cloud data
      final meals = await _firestoreService.getMeals(userId);
      final userFoods = await _firestoreService.getUserFoods(userId);
      final favorites = await _firestoreService.getFavorites(userId);

      debugPrint('📦 [SyncProvider] Cloud data:');
      debugPrint('  - Meals: ${meals.length}');
      debugPrint('  - User Foods: ${userFoods.length}');
      debugPrint('  - Favorites: ${favorites.length}');

      // 2. Save to local database (this will merge/update existing entries)
      for (final meal in meals) {
        await _databaseHelper.insertMealEntry(meal.toMap());
      }

      for (final food in userFoods) {
        await _userFoodRepo.createFood(
          userId: food.userId,
          name: food.name,
          portionSize: food.portionSize,
          calories: food.calories,
          protein: food.protein,
          carbs: food.carbs,
          fat: food.fat,
          imagePath: food.imagePath,
          source: food.source,
          aiConfidence: food.aiConfidence,
        );
      }

      for (final favorite in favorites) {
        await _favoriteRepo.addFavorite(favorite.userId, favorite.foodId, favorite.foodSource);
      }

      _setSuccess('Tải dữ liệu từ cloud thành công! ⬇️');
      debugPrint('✅ [SyncProvider] Sync from cloud completed');
      
      return true;
    } catch (e) {
      _setError('Lỗi tải dữ liệu: ${e.toString()}');
      debugPrint('❌ [SyncProvider] Sync from cloud error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bi-directional sync (smart merge)
  /// 
  /// Syncs both ways: uploads local changes and downloads cloud changes.
  /// This is the recommended sync method for most use cases.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> syncBothWays(String userId) async {
    try {
      debugPrint('🔄 [SyncProvider] Starting bi-directional sync');

      // 1. Upload local data to cloud
      final uploadSuccess = await syncToCloud(userId);
      if (!uploadSuccess) {
        debugPrint('⚠️ [SyncProvider] Upload failed, skipping download');
        return false;
      }

      // 2. Download cloud data to local
      final downloadSuccess = await syncFromCloud(userId);
      if (!downloadSuccess) {
        debugPrint('⚠️ [SyncProvider] Download failed');
        return false;
      }

      _setSuccess('Đồng bộ hoàn tất! 🔄');
      debugPrint('✅ [SyncProvider] Bi-directional sync completed');
      
      return true;
    } catch (e) {
      _setError('Lỗi đồng bộ: ${e.toString()}');
      debugPrint('❌ [SyncProvider] Bi-directional sync error: $e');
      return false;
    }
  }

  // ==================== INDIVIDUAL ITEM SYNC ====================
  
  /// Sync a single meal to cloud (for real-time updates)
  /// 
  /// Use this when adding/updating a meal to immediately sync to Firestore.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [meal]: Meal to sync
  Future<void> syncMealToCloud(String userId, MealEntryModel meal) async {
    try {
      debugPrint('☁️ [SyncProvider] Syncing single meal to cloud: ${meal.foodName}');
      await _firestoreService.syncMeal(userId, meal);
      debugPrint('✅ [SyncProvider] Meal synced successfully');
    } catch (e) {
      debugPrint('❌ [SyncProvider] Error syncing meal: $e');
      // Don't rethrow - sync errors shouldn't block user actions
    }
  }

  /// Delete a meal from cloud
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [mealId]: Meal ID to delete
  Future<void> deleteMealFromCloud(String userId, String mealId) async {
    try {
      debugPrint('🗑️ [SyncProvider] Deleting meal from cloud: $mealId');
      await _firestoreService.deleteMeal(userId, mealId);
      debugPrint('✅ [SyncProvider] Meal deleted from cloud');
    } catch (e) {
      debugPrint('❌ [SyncProvider] Error deleting meal: $e');
    }
  }

  /// Sync a single user food to cloud
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [userFood]: User food to sync
  Future<void> syncUserFoodToCloud(String userId, userFood) async {
    try {
      debugPrint('☁️ [SyncProvider] Syncing user food to cloud: ${userFood.name}');
      await _firestoreService.syncUserFood(userId, userFood);
      debugPrint('✅ [SyncProvider] User food synced successfully');
    } catch (e) {
      debugPrint('❌ [SyncProvider] Error syncing user food: $e');
    }
  }

  /// Delete a user food from cloud
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [foodId]: Food ID to delete
  Future<void> deleteUserFoodFromCloud(String userId, String foodId) async {
    try {
      debugPrint('🗑️ [SyncProvider] Deleting user food from cloud: $foodId');
      await _firestoreService.deleteUserFood(userId, foodId);
      debugPrint('✅ [SyncProvider] User food deleted from cloud');
    } catch (e) {
      debugPrint('❌ [SyncProvider] Error deleting user food: $e');
    }
  }

  /// Sync a favorite to cloud
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [favorite]: Favorite to sync
  Future<void> syncFavoriteToCloud(String userId, favorite) async {
    try {
      debugPrint('☁️ [SyncProvider] Syncing favorite to cloud');
      await _firestoreService.syncFavorite(userId, favorite);
      debugPrint('✅ [SyncProvider] Favorite synced successfully');
    } catch (e) {
      debugPrint('❌ [SyncProvider] Error syncing favorite: $e');
    }
  }

  /// Delete a favorite from cloud
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [foodId]: Food ID
  /// - [source]: Food source
  Future<void> deleteFavoriteFromCloud(String userId, String foodId, String source) async {
    try {
      debugPrint('🗑️ [SyncProvider] Deleting favorite from cloud');
      await _firestoreService.deleteFavorite(userId, foodId, source);
      debugPrint('✅ [SyncProvider] Favorite deleted from cloud');
    } catch (e) {
      debugPrint('❌ [SyncProvider] Error deleting favorite: $e');
    }
  }

  // ==================== AUTO SYNC ====================
  
  /// Auto-sync on app launch
  /// 
  /// Call this in app initialization (e.g., in main.dart or SplashScreen).
  /// This will sync data in the background without blocking UI.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  Future<void> autoSyncOnLaunch(String userId) async {
    try {
      debugPrint('🚀 [SyncProvider] Auto-sync on launch');

      // First, sync from cloud to get latest data
      await syncFromCloud(userId);
      
      // Then enable real-time sync
      enableRealTimeSync(userId);
      
      debugPrint('✅ [SyncProvider] Auto-sync completed');
    } catch (e) {
      debugPrint('❌ [SyncProvider] Auto-sync error: $e');
    }
  }

  // ==================== REAL-TIME SYNC ====================
  
  /// Stream subscriptions for real-time listeners
  StreamSubscription? _mealsListener;
  StreamSubscription? _userFoodsListener;
  StreamSubscription? _favoritesListener;

  /// Flag to prevent infinite sync loops
  bool _isProcessingRemoteChange = false;

  /// Enable real-time sync for all data types
  /// 
  /// Listens to Firestore changes and automatically updates local database.
  /// This enables true real-time synchronization across devices.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [onMealsUpdated]: Optional callback when meals are updated
  /// - [onUserFoodsUpdated]: Optional callback when user foods are updated
  /// - [onFavoritesUpdated]: Optional callback when favorites are updated
  void enableRealTimeSync(
    String userId, {
    VoidCallback? onMealsUpdated,
    VoidCallback? onUserFoodsUpdated,
    VoidCallback? onFavoritesUpdated,
  }) {
    debugPrint('👂 [SyncProvider] Enabling real-time sync for user: $userId');

    // Cancel any existing listeners first
    disableRealTimeSync();

    // 1. Listen to meals changes
    _mealsListener = _firestoreService.listenToMeals(userId).listen(
      (cloudMeals) async {
        if (_isProcessingRemoteChange) {
          debugPrint('⏭️ [SyncProvider] Skipping meals update (already processing)');
          return;
        }

        try {
          _isProcessingRemoteChange = true;
          debugPrint('🔄 [SyncProvider] Real-time meals update: ${cloudMeals.length} meals');

          // Update local database
          for (final meal in cloudMeals) {
            await _databaseHelper.insertMealEntry(meal.toMap());
          }

          // Notify listeners
          if (onMealsUpdated != null) {
            onMealsUpdated();
          }
          notifyListeners();

          debugPrint('✅ [SyncProvider] Meals synced to local database');
        } catch (e) {
          debugPrint('❌ [SyncProvider] Error processing meals update: $e');
        } finally {
          _isProcessingRemoteChange = false;
        }
      },
      onError: (error) {
        debugPrint('❌ [SyncProvider] Meals real-time sync error: $error');
        _isProcessingRemoteChange = false;
      },
    );

    // 2. Listen to user foods changes
    _userFoodsListener = _firestoreService.listenToUserFoods(userId).listen(
      (cloudUserFoods) async {
        if (_isProcessingRemoteChange) {
          debugPrint('⏭️ [SyncProvider] Skipping user foods update (already processing)');
          return;
        }

        try {
          _isProcessingRemoteChange = true;
          debugPrint('🔄 [SyncProvider] Real-time user foods update: ${cloudUserFoods.length} foods');

          // Update local database with INSERT OR REPLACE to avoid duplicates
          for (final food in cloudUserFoods) {
            // Use upsert instead of createFood to avoid duplicates
            await _databaseHelper.database.then((db) => db.insert(
              'user_foods',
              {
                'id': food.id,
                'user_id': food.userId,
                'name': food.name,
                'portion_size': food.portionSize,
                'calories': food.calories,
                'protein': food.protein,
                'carbs': food.carbs,
                'fat': food.fat,
                'image_path': food.imagePath,
                'source': food.source,
                'ai_confidence': food.aiConfidence,
                'created_at': food.createdAt.toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace, // ✅ Replace if exists
            ));
          }

          // Notify listeners
          if (onUserFoodsUpdated != null) {
            onUserFoodsUpdated();
          }
          notifyListeners();

          debugPrint('✅ [SyncProvider] User foods synced to local database');
        } catch (e) {
          debugPrint('❌ [SyncProvider] Error processing user foods update: $e');
        } finally {
          _isProcessingRemoteChange = false;
        }
      },
      onError: (error) {
        debugPrint('❌ [SyncProvider] User foods real-time sync error: $error');
        _isProcessingRemoteChange = false;
      },
    );

    // 3. Listen to favorites changes
    _favoritesListener = _firestoreService.listenToFavorites(userId).listen(
      (cloudFavorites) async {
        if (_isProcessingRemoteChange) {
          debugPrint('⏭️ [SyncProvider] Skipping favorites update (already processing)');
          return;
        }

        try {
          _isProcessingRemoteChange = true;
          debugPrint('🔄 [SyncProvider] Real-time favorites update: ${cloudFavorites.length} favorites');

          // Update local database
          for (final favorite in cloudFavorites) {
            await _favoriteRepo.addFavorite(favorite.userId, favorite.foodId, favorite.foodSource);
          }

          // Notify listeners
          if (onFavoritesUpdated != null) {
            onFavoritesUpdated();
          }
          notifyListeners();

          debugPrint('✅ [SyncProvider] Favorites synced to local database');
        } catch (e) {
          debugPrint('❌ [SyncProvider] Error processing favorites update: $e');
        } finally {
          _isProcessingRemoteChange = false;
        }
      },
      onError: (error) {
        debugPrint('❌ [SyncProvider] Favorites real-time sync error: $error');
        _isProcessingRemoteChange = false;
      },
    );

    debugPrint('✅ [SyncProvider] Real-time sync enabled for all data types');
  }

  /// Disable real-time sync
  /// 
  /// Cancels all active listeners and cleans up resources.
  /// Call this when user signs out or when sync is no longer needed.
  void disableRealTimeSync() {
    debugPrint('👋 [SyncProvider] Disabling real-time sync');
    
    _mealsListener?.cancel();
    _mealsListener = null;
    
    _userFoodsListener?.cancel();
    _userFoodsListener = null;
    
    _favoritesListener?.cancel();
    _favoritesListener = null;
    
    _isProcessingRemoteChange = false;
    
    debugPrint('✅ [SyncProvider] Real-time sync disabled');
  }

  /// Check if real-time sync is currently active
  bool get isRealTimeSyncEnabled {
    return _mealsListener != null || 
           _userFoodsListener != null || 
           _favoritesListener != null;
  }

  @override
  void dispose() {
    disableRealTimeSync();
    super.dispose();
  }
}

