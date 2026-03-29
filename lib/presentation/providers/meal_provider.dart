import 'package:flutter/foundation.dart';
import '../../data/models/meal_entry_model.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/services/image_service.dart';
import 'sync_provider.dart';

/// Meal Provider - Manages meal entries and daily stats
class MealProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncProvider? _syncProvider;

  /// Constructor with optional SyncProvider for real-time sync
  MealProvider({SyncProvider? syncProvider}) : _syncProvider = syncProvider;

  List<MealEntryModel> _todayMeals = [];
  List<MealEntryModel> _recentMeals = []; // ✅ Recent meals (last 3, any date)
  Map<String, dynamic> _dailySummary = {};
  bool _isLoading = false;
  String _selectedDate = '';

  List<MealEntryModel> get todayMeals => _todayMeals;
  List<MealEntryModel> get recentMeals => _recentMeals; // ✅ Getter for recent meals
  Map<String, dynamic> get dailySummary => _dailySummary;
  bool get isLoading => _isLoading;
  String get selectedDate => _selectedDate;

  /// Get total calories for today
  double get totalCalories => 
      (_dailySummary['total_calories'] as num?)?.toDouble() ?? 0.0;

  /// Get total protein for today
  double get totalProtein => 
      (_dailySummary['total_protein'] as num?)?.toDouble() ?? 0.0;

  /// Get total carbs for today
  double get totalCarbs => 
      (_dailySummary['total_carbs'] as num?)?.toDouble() ?? 0.0;

  /// Get total fat for today
  double get totalFat => 
      (_dailySummary['total_fat'] as num?)?.toDouble() ?? 0.0;

  /// Get meal count for today
  int get mealCount => 
      (_dailySummary['meal_count'] as num?)?.toInt() ?? 0;

  /// Load meals for a specific date
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<void> loadMealsForDate(DateTime date) async {
    _isLoading = true;
    _selectedDate = DateFormatter.formatDateOnly(date);
    notifyListeners();

    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ MealProvider: No userId found for loadMealsForDate');
        _todayMeals = [];
        _dailySummary = {};
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load meals and summary FOR THIS USER ONLY
      final mealsData = await _dbHelper.getMealEntriesByDate(userId, _selectedDate);
      _todayMeals = mealsData.map((data) => MealEntryModel.fromMap(data)).toList();

      final summaryData = await _dbHelper.getDailySummary(userId, _selectedDate);
      _dailySummary = summaryData;

      debugPrint('✅ MealProvider: Loaded ${_todayMeals.length} meals for user $userId on $_selectedDate');
    } catch (e) {
      debugPrint('❌ MealProvider: Error loading meals: $e');
      _todayMeals = [];
      _dailySummary = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load today's meals
  Future<void> loadTodayMeals() async {
    await loadMealsForDate(DateTime.now());
  }

  /// Load recent meals (last 3 meals, regardless of date)
  /// 
  /// This is used for the "Recent Meals" section on Home Screen
  /// to show the most recent meals even if user hasn't added meals today
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<void> loadRecentMeals() async {
    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ MealProvider: No userId found, skipping loadRecentMeals');
        _recentMeals = [];
        notifyListeners();
        return;
      }

      // Get last 3 meals from database (paginated query) FOR THIS USER ONLY
      final mealsData = await _dbHelper.getMealsPaginated(
        userId: userId,
        limit: 3,
        offset: 0,
        searchQuery: null,
        mealType: null,
      );
      _recentMeals = mealsData.map((data) => MealEntryModel.fromMap(data)).toList();
      notifyListeners();
      debugPrint('✅ MealProvider: Loaded ${_recentMeals.length} recent meals for user $userId');
    } catch (e) {
      debugPrint('❌ MealProvider: Error loading recent meals: $e');
      _recentMeals = [];
      notifyListeners();
    }
  }

  /// Add a new meal entry
  Future<void> addMealEntry(MealEntryModel meal) async {
    try {
      // 1. Save to local database
      await _dbHelper.insertMealEntry(meal.toMap());
      
      // 2. Sync to cloud (real-time)
      if (_syncProvider != null) {
        final firebaseUid = await SharedPrefsHelper.getFirebaseUid();
        if (firebaseUid != null) {
          await _syncProvider.syncMealToCloud(firebaseUid, meal);
          debugPrint('☁️ [MealProvider] Meal synced to cloud');
        }
      }
      
      // 3. Reload UI
      await loadMealsForDate(meal.date);
      await loadRecentMeals(); // ✅ Also reload recent meals for Home Screen
    } catch (e) {
      debugPrint('Error adding meal: $e');
      rethrow;
    }
  }

  /// Update a meal entry
  Future<void> updateMealEntry(MealEntryModel meal) async {
    try {
      // 1. Update local database
      await _dbHelper.updateMealEntry(meal.toMap());
      
      // 2. Sync to cloud (real-time)
      if (_syncProvider != null) {
        final firebaseUid = await SharedPrefsHelper.getFirebaseUid();
        if (firebaseUid != null) {
          await _syncProvider.syncMealToCloud(firebaseUid, meal);
          debugPrint('☁️ [MealProvider] Meal update synced to cloud');
        }
      }
      
      // 3. Reload UI
      await loadMealsForDate(meal.date);
      await loadRecentMeals(); // ✅ Also reload recent meals for Home Screen
    } catch (e) {
      debugPrint('Error updating meal: $e');
      rethrow;
    }
  }

  /// Delete a meal entry
  /// Delete meal entry and its image
  Future<void> deleteMealEntry(String id) async {
    try {
      // Get meal entry to find image path
      final meal = _todayMeals.firstWhere(
        (m) => m.id == id,
        orElse: () => throw Exception('Meal not found'),
      );

      // 1. Delete from local database
      await _dbHelper.deleteMealEntry(id);

      // 2. Delete from cloud (real-time)
      if (_syncProvider != null) {
        final firebaseUid = await SharedPrefsHelper.getFirebaseUid();
        if (firebaseUid != null) {
          await _syncProvider.deleteMealFromCloud(firebaseUid, id);
          debugPrint('☁️ [MealProvider] Meal deletion synced to cloud');
        }
      }

      // 3. Delete image if exists
      if (meal.imagePath != null && meal.imagePath!.isNotEmpty) {
        await ImageService.instance.deleteImage(meal.imagePath);
        debugPrint('🗑️ MealProvider: Deleted meal image');
      }

      // 4. Reload UI
      await loadTodayMeals();
      await loadRecentMeals(); // ✅ Also reload recent meals for Home Screen
    } catch (e) {
      debugPrint('❌ MealProvider: Error deleting meal: $e');
      rethrow;
    }
  }

  /// Refresh meals from sync (called by SyncProvider when remote changes detected)
  Future<void> refreshFromSync() async {
    try {
      debugPrint('🔄 [MealProvider] Refreshing from sync');
      await loadTodayMeals();
      await loadRecentMeals();
    } catch (e) {
      debugPrint('❌ [MealProvider] Error refreshing from sync: $e');
    }
  }

  /// Get meals by type for today
  List<MealEntryModel> getMealsByType(String mealType) {
    return _todayMeals
        .where((meal) => meal.mealType.toLowerCase() == mealType.toLowerCase())
        .toList();
  }

  /// Check if a meal type has entries
  bool hasMealsForType(String mealType) {
    return getMealsByType(mealType).isNotEmpty;
  }

  /// Get total calories for a meal type
  double getCaloriesForType(String mealType) {
    final meals = getMealsByType(mealType);
    return meals.fold(0.0, (sum, meal) => sum + meal.totalCalories);
  }
}

