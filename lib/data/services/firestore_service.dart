import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/meal_entry_model.dart';
import '../models/user_food_model.dart';
import '../models/favorite_food_model.dart';

/// Firestore Service
/// 
/// Handles all Firestore database operations for syncing user data to cloud.
/// 
/// **Architecture:**
/// - Local SQLite is the primary database (offline-first)
/// - Firestore is used for backup and sync across devices
/// - Data flows: Local → Firestore (on changes) and Firestore → Local (on sync)
/// 
/// **Collections Structure:**
/// ```
/// users/{userId}/
///   ├── meals/{mealId} - MealEntry documents
///   ├── userFoods/{foodId} - UserFood documents
///   └── favorites/{favoriteId} - FavoriteFood documents
/// ```
/// 
/// **Usage:**
/// ```dart
/// final firestoreService = FirestoreService();
/// 
/// // Sync meal to cloud
/// await firestoreService.syncMeal(userId, mealEntry);
/// 
/// // Fetch all meals from cloud
/// final meals = await firestoreService.getMeals(userId);
/// ```
class FirestoreService {
  // ==================== FIRESTORE INSTANCE ====================
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== COLLECTION NAMES ====================
  
  static const String _usersCollection = 'users';
  static const String _mealsSubCollection = 'meals';
  static const String _userFoodsSubCollection = 'userFoods';
  static const String _favoritesSubCollection = 'favorites';

  // ==================== MEAL OPERATIONS ====================
  
  /// Sync meal entry to Firestore
  /// 
  /// Uploads a meal entry to the user's cloud storage.
  /// If the meal already exists (by ID), it will be updated.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [meal]: Meal entry to sync
  Future<void> syncMeal(String userId, MealEntryModel meal) async {
    try {
      debugPrint('☁️ [Firestore] Syncing meal: ${meal.id}');

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_mealsSubCollection)
          .doc(meal.id.toString())
          .set(meal.toMap(), SetOptions(merge: true)); // Merge to avoid overwriting other fields

      debugPrint('✅ [Firestore] Meal synced successfully');
    } catch (e) {
      debugPrint('❌ [Firestore] Error syncing meal: $e');
      rethrow; // Let caller handle error
    }
  }

  /// Sync multiple meals to Firestore (batch operation)
  /// 
  /// More efficient for syncing many meals at once.
  /// Uses Firestore batch writes (max 500 operations per batch).
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [meals]: List of meals to sync
  Future<void> syncMealsBatch(String userId, List<MealEntryModel> meals) async {
    try {
      debugPrint('☁️ [Firestore] Batch syncing ${meals.length} meals');

      // Firestore batch limit is 500 operations
      const batchSize = 500;
      
      for (var i = 0; i < meals.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < meals.length) ? i + batchSize : meals.length;
        final batchMeals = meals.sublist(i, end);

        for (final meal in batchMeals) {
          final docRef = _firestore
              .collection(_usersCollection)
              .doc(userId)
              .collection(_mealsSubCollection)
              .doc(meal.id.toString());
          
          batch.set(docRef, meal.toMap(), SetOptions(merge: true));
        }

        await batch.commit();
        debugPrint('✅ [Firestore] Batch ${i ~/ batchSize + 1} synced (${batchMeals.length} meals)');
      }

      debugPrint('✅ [Firestore] All meals synced successfully');
    } catch (e) {
      debugPrint('❌ [Firestore] Error syncing meals batch: $e');
      rethrow;
    }
  }

  /// Get all meals for a user from Firestore
  /// 
  /// Fetches all meal entries from cloud storage.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: List of meal entries
  Future<List<MealEntryModel>> getMeals(String userId) async {
    try {
      debugPrint('☁️ [Firestore] Fetching meals for user: $userId');

      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_mealsSubCollection)
          .get();

      final meals = snapshot.docs
          .map((doc) => MealEntryModel.fromMap(doc.data()))
          .toList();

      debugPrint('✅ [Firestore] Fetched ${meals.length} meals');
      return meals;
    } catch (e) {
      debugPrint('❌ [Firestore] Error fetching meals: $e');
      rethrow;
    }
  }

  /// Get meals for a specific date range
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [startDate]: Start date (inclusive)
  /// - [endDate]: End date (inclusive)
  /// 
  /// Returns: List of meal entries in the date range
  Future<List<MealEntryModel>> getMealsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint('☁️ [Firestore] Fetching meals from $startDate to $endDate');

      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_mealsSubCollection)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      final meals = snapshot.docs
          .map((doc) => MealEntryModel.fromMap(doc.data()))
          .toList();

      debugPrint('✅ [Firestore] Fetched ${meals.length} meals');
      return meals;
    } catch (e) {
      debugPrint('❌ [Firestore] Error fetching meals by date: $e');
      rethrow;
    }
  }

  /// Delete a meal from Firestore
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [mealId]: Meal ID to delete
  Future<void> deleteMeal(String userId, String mealId) async {
    try {
      debugPrint('☁️ [Firestore] Deleting meal: $mealId');

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_mealsSubCollection)
          .doc(mealId)
          .delete();

      debugPrint('✅ [Firestore] Meal deleted successfully');
    } catch (e) {
      debugPrint('❌ [Firestore] Error deleting meal: $e');
      rethrow;
    }
  }

  // ==================== USER FOOD OPERATIONS ====================
  
  /// Sync user food to Firestore
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [userFood]: User food to sync
  Future<void> syncUserFood(String userId, UserFoodModel userFood) async {
    try {
      debugPrint('☁️ [Firestore] Syncing user food: ${userFood.id}');

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_userFoodsSubCollection)
          .doc(userFood.id)
          .set(userFood.toMap(), SetOptions(merge: true));

      debugPrint('✅ [Firestore] User food synced successfully');
    } catch (e) {
      debugPrint('❌ [Firestore] Error syncing user food: $e');
      rethrow;
    }
  }

  /// Get all user foods from Firestore
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: List of user foods
  Future<List<UserFoodModel>> getUserFoods(String userId) async {
    try {
      debugPrint('☁️ [Firestore] Fetching user foods for user: $userId');

      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_userFoodsSubCollection)
          .get();

      final userFoods = snapshot.docs
          .map((doc) => UserFoodModel.fromMap(doc.data()))
          .toList();

      debugPrint('✅ [Firestore] Fetched ${userFoods.length} user foods');
      return userFoods;
    } catch (e) {
      debugPrint('❌ [Firestore] Error fetching user foods: $e');
      rethrow;
    }
  }

  /// Delete user food from Firestore
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [foodId]: Food ID to delete
  Future<void> deleteUserFood(String userId, String foodId) async {
    try {
      debugPrint('☁️ [Firestore] Deleting user food: $foodId');

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_userFoodsSubCollection)
          .doc(foodId)
          .delete();

      debugPrint('✅ [Firestore] User food deleted successfully');
    } catch (e) {
      debugPrint('❌ [Firestore] Error deleting user food: $e');
      rethrow;
    }
  }

  // ==================== FAVORITE OPERATIONS ====================
  
  /// Sync favorite food to Firestore
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [favorite]: Favorite food to sync
  Future<void> syncFavorite(String userId, FavoriteFoodModel favorite) async {
    try {
      debugPrint('☁️ [Firestore] Syncing favorite: ${favorite.id}');

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_favoritesSubCollection)
          .doc('${favorite.id}_${favorite.foodSource}') // Composite key: id + foodSource
          .set(favorite.toMap(), SetOptions(merge: true));

      debugPrint('✅ [Firestore] Favorite synced successfully');
    } catch (e) {
      debugPrint('❌ [Firestore] Error syncing favorite: $e');
      rethrow;
    }
  }

  /// Get all favorites from Firestore
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: List of favorites
  Future<List<FavoriteFoodModel>> getFavorites(String userId) async {
    try {
      debugPrint('☁️ [Firestore] Fetching favorites for user: $userId');

      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_favoritesSubCollection)
          .get();

      final favorites = snapshot.docs
          .map((doc) => FavoriteFoodModel.fromMap(doc.data()))
          .toList();

      debugPrint('✅ [Firestore] Fetched ${favorites.length} favorites');
      return favorites;
    } catch (e) {
      debugPrint('❌ [Firestore] Error fetching favorites: $e');
      rethrow;
    }
  }

  /// Delete favorite from Firestore
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [foodId]: Food ID
  /// - [source]: Food source ('builtin', 'custom', etc.)
  Future<void> deleteFavorite(String userId, String foodId, String source) async {
    try {
      debugPrint('☁️ [Firestore] Deleting favorite: $foodId ($source)');

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_favoritesSubCollection)
          .doc('${foodId}_$source')
          .delete();

      debugPrint('✅ [Firestore] Favorite deleted successfully');
    } catch (e) {
      debugPrint('❌ [Firestore] Error deleting favorite: $e');
      rethrow;
    }
  }

  // ==================== SYNC OPERATIONS ====================
  
  /// Full sync: Upload all local data to Firestore
  /// 
  /// This should be called periodically or when user explicitly requests sync.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// - [meals]: All meals to sync
  /// - [userFoods]: All user foods to sync
  /// - [favorites]: All favorites to sync
  Future<void> fullSync({
    required String userId,
    required List<MealEntryModel> meals,
    required List<UserFoodModel> userFoods,
    required List<FavoriteFoodModel> favorites,
  }) async {
    try {
      debugPrint('☁️ [Firestore] Starting full sync for user: $userId');
      debugPrint('  - ${meals.length} meals');
      debugPrint('  - ${userFoods.length} user foods');
      debugPrint('  - ${favorites.length} favorites');

      // Sync meals in batches
      await syncMealsBatch(userId, meals);

      // Sync user foods
      for (final food in userFoods) {
        await syncUserFood(userId, food);
      }

      // Sync favorites
      for (final favorite in favorites) {
        await syncFavorite(userId, favorite);
      }

      debugPrint('✅ [Firestore] Full sync completed successfully');
    } catch (e) {
      debugPrint('❌ [Firestore] Error during full sync: $e');
      rethrow;
    }
  }

  /// Listen to real-time updates for meals
  /// 
  /// Sets up a real-time listener for changes to user's meals.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: Stream of meal entries that updates in real-time
  Stream<List<MealEntryModel>> listenToMeals(String userId) {
    debugPrint('👂 [Firestore] Setting up real-time listener for meals');

    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_mealsSubCollection)
        .snapshots()
        .map((snapshot) {
          final meals = snapshot.docs
              .map((doc) => MealEntryModel.fromMap(doc.data()))
              .toList();
          debugPrint('🔄 [Firestore] Meals updated: ${meals.length} meals');
          return meals;
        });
  }

  /// Listen to real-time updates for user foods
  /// 
  /// Sets up a real-time listener for changes to user's custom foods.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: Stream of user foods that updates in real-time
  Stream<List<UserFoodModel>> listenToUserFoods(String userId) {
    debugPrint('👂 [Firestore] Setting up real-time listener for user foods');

    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_userFoodsSubCollection)
        .snapshots()
        .map((snapshot) {
          final userFoods = snapshot.docs
              .map((doc) => UserFoodModel.fromMap(doc.data()))
              .toList();
          debugPrint('🔄 [Firestore] User foods updated: ${userFoods.length} foods');
          return userFoods;
        });
  }

  /// Listen to real-time updates for favorites
  /// 
  /// Sets up a real-time listener for changes to user's favorite foods.
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  /// 
  /// Returns: Stream of favorites that updates in real-time
  Stream<List<FavoriteFoodModel>> listenToFavorites(String userId) {
    debugPrint('👂 [Firestore] Setting up real-time listener for favorites');

    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_favoritesSubCollection)
        .snapshots()
        .map((snapshot) {
          final favorites = snapshot.docs
              .map((doc) => FavoriteFoodModel.fromMap(doc.data()))
              .toList();
          debugPrint('🔄 [Firestore] Favorites updated: ${favorites.length} favorites');
          return favorites;
        });
  }

  // ==================== USER MANAGEMENT ====================
  
  /// Delete all user data from Firestore
  /// 
  /// Permanently deletes all user's cloud data.
  /// Use with caution!
  /// 
  /// Parameters:
  /// - [userId]: User's unique ID
  Future<void> deleteAllUserData(String userId) async {
    try {
      debugPrint('🗑️ [Firestore] Deleting all data for user: $userId');

      final userDoc = _firestore.collection(_usersCollection).doc(userId);

      // Delete all subcollections
      await _deleteCollection(userDoc.collection(_mealsSubCollection));
      await _deleteCollection(userDoc.collection(_userFoodsSubCollection));
      await _deleteCollection(userDoc.collection(_favoritesSubCollection));

      // Delete user document
      await userDoc.delete();

      debugPrint('✅ [Firestore] All user data deleted');
    } catch (e) {
      debugPrint('❌ [Firestore] Error deleting user data: $e');
      rethrow;
    }
  }

  /// Helper: Delete all documents in a collection
  Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}

