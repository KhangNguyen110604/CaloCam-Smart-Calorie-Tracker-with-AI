import 'package:flutter/foundation.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../../core/utils/date_formatter.dart';

/// Water Intake Provider
/// 
/// Manages water intake tracking state and operations:
/// - Daily water intake logging
/// - Goal tracking (default 2000ml)
/// - Quick add shortcuts (200ml, 500ml, 1000ml)
/// - History management
class WaterProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  // State
  int _currentIntake = 0; // milliliters
  int _dailyGoal = 2000; // milliliters (default)
  bool _isLoading = false;
  
  // Getters
  int get currentIntake => _currentIntake;
  int get dailyGoal => _dailyGoal;
  bool get isLoading => _isLoading;
  double get progress => _currentIntake / _dailyGoal;
  int get remainingIntake => (_dailyGoal - _currentIntake).clamp(0, _dailyGoal);
  bool get isGoalReached => _currentIntake >= _dailyGoal;
  
  /// Load today's water intake
  /// 
  /// Fetches current day's water data from database
  /// Creates new entry if none exists for today
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<void> loadTodayIntake() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ WaterProvider: No userId found');
        _currentIntake = 0;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final today = DateFormatter.formatDate(DateTime.now());
      
      // Get water intake for today FOR THIS USER ONLY
      final data = await _db.getWaterIntakeByDate(userId, today);
      
      if (data != null) {
        _currentIntake = data['milliliters'] as int;
      } else {
        _currentIntake = 0;
      }
      
      debugPrint('✅ Water intake loaded for user $userId: $_currentIntake ml / $_dailyGoal ml');
    } catch (e) {
      debugPrint('❌ Error loading water intake: $e');
      _currentIntake = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Add water intake
  /// 
  /// Adds specified amount (in ml) to today's total
  /// Updates database automatically
  /// 
  /// Parameters:
  /// - [milliliters]: Amount to add (e.g., 200, 500, 1000)
  /// 
  /// Returns: true if successful, false otherwise
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<bool> addWater(int milliliters) async {
    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ WaterProvider: No userId found for addWater');
        return false;
      }

      final today = DateFormatter.formatDate(DateTime.now());
      final newTotal = _currentIntake + milliliters;
      
      // Calculate glasses (250ml per glass)
      final glasses = (newTotal / 250).ceil();
      
      // Save to database FOR THIS USER ONLY
      await _db.upsertWaterIntake({
        'user_id': userId,
        'date': today,
        'glasses': glasses,
        'milliliters': newTotal,
      });
      
      // Update state
      _currentIntake = newTotal;
      notifyListeners();
      
      debugPrint('✅ Water added for user $userId: +$milliliters ml (Total: $_currentIntake ml)');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding water: $e');
      return false;
    }
  }
  
  /// Remove water intake
  /// 
  /// Subtracts specified amount (in ml) from today's total
  /// Useful for undo or corrections
  /// 
  /// Parameters:
  /// - [milliliters]: Amount to remove
  /// 
  /// Returns: true if successful, false otherwise
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<bool> removeWater(int milliliters) async {
    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ WaterProvider: No userId found for removeWater');
        return false;
      }

      final today = DateFormatter.formatDate(DateTime.now());
      final newTotal = (_currentIntake - milliliters).clamp(0, 100000);
      
      final glasses = (newTotal / 250).ceil();
      
      await _db.upsertWaterIntake({
        'user_id': userId,
        'date': today,
        'glasses': glasses,
        'milliliters': newTotal,
      });
      
      _currentIntake = newTotal;
      notifyListeners();
      
      debugPrint('✅ Water removed for user $userId: -$milliliters ml (Total: $_currentIntake ml)');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing water: $e');
      return false;
    }
  }
  
  /// Reset today's water intake
  /// 
  /// Sets today's intake to 0
  /// Useful for testing or user corrections
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<void> resetTodayIntake() async {
    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ WaterProvider: No userId found for resetTodayIntake');
        return;
      }

      final today = DateFormatter.formatDate(DateTime.now());
      
      await _db.upsertWaterIntake({
        'user_id': userId,
        'date': today,
        'glasses': 0,
        'milliliters': 0,
      });
      
      _currentIntake = 0;
      notifyListeners();
      
      debugPrint('✅ Water intake reset to 0 for user $userId');
    } catch (e) {
      debugPrint('❌ Error resetting water intake: $e');
    }
  }
  
  /// Update daily goal
  /// 
  /// Changes the daily water intake goal
  /// 
  /// Parameters:
  /// - [newGoal]: New goal in milliliters (e.g., 2000, 2500, 3000)
  void updateDailyGoal(int newGoal) {
    _dailyGoal = newGoal.clamp(500, 5000); // Min 500ml, Max 5000ml
    notifyListeners();
    debugPrint('✅ Daily water goal updated: $_dailyGoal ml');
  }
  
  /// Get water intake history
  /// 
  /// Fetches water intake data for the past N days
  /// Useful for trends and statistics
  /// 
  /// Parameters:
  /// - [days]: Number of days to fetch (default 7)
  /// 
  /// Returns: List of water intake records
  /// 
  /// ⚠️ CRITICAL: Filters by userId for data isolation
  Future<List<Map<String, dynamic>>> getWaterHistory(int days) async {
    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ WaterProvider: No userId found for getWaterHistory');
        return [];
      }

      final db = await _db.database;
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      
      final results = await db.query(
        'water_intake',
        where: 'user_id = ? AND date >= ? AND date <= ?',
        whereArgs: [
          userId,
          DateFormatter.formatDate(startDate),
          DateFormatter.formatDate(endDate),
        ],
        orderBy: 'date DESC',
      );
      
      debugPrint('✅ Water history loaded for user $userId: ${results.length} records');
      return results;
    } catch (e) {
      debugPrint('❌ Error loading water history: $e');
      return [];
    }
  }
}

