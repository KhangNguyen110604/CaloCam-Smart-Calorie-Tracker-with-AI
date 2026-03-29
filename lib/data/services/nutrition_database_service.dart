import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../datasources/local/database_helper.dart';
import '../models/nutrition_data_model.dart';

/// Nutrition Database Service
/// 
/// Manages local nutrition database (SQLite).
/// This is the FIRST layer - fastest, offline.
/// 
/// Responsibilities:
/// - Search nutrition data by food name
/// - Save nutrition data from API (cache)
/// - Pre-populate Vietnamese foods
/// - Track usage statistics
/// 
/// Usage:
/// ```dart
/// final service = NutritionDatabaseService.instance;
/// final nutrition = await service.searchByName('Phở bò');
/// if (nutrition != null) {
///   print('Found: ${nutrition.caloriesPer100g} cal/100g');
/// }
/// ```
class NutritionDatabaseService {
  // Singleton pattern
  static final NutritionDatabaseService _instance = NutritionDatabaseService._internal();
  static NutritionDatabaseService get instance => _instance;
  NutritionDatabaseService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Search nutrition data by food name
  /// 
  /// [foodName]: Food name to search (Vietnamese or English)
  /// 
  /// Returns: NutritionDataModel if found, null otherwise
  /// 
  /// Search strategy:
  /// 1. Normalize food name (lowercase, trim)
  /// 2. Search exact match first
  /// 3. Search partial match (LIKE)
  /// 4. Update usage_count and last_used if found
  /// 
  /// Example:
  /// ```dart
  /// final nutrition = await service.searchByName('Phở bò');
  /// if (nutrition != null) {
  ///   print('Found: ${nutrition.caloriesPer100g} cal/100g');
  ///   print('Source: ${nutrition.source}');
  /// }
  /// ```
  Future<NutritionDataModel?> searchByName(String foodName) async {
    try {
      debugPrint('🔍 [NutritionDB] Searching: $foodName');
      
      // Normalize food name (lowercase, trim)
      final normalizedName = _normalizeFoodName(foodName);
      
      final db = await _db.database;
      
      // Try exact match first
      List<Map<String, dynamic>> results = await db.query(
        'nutrition_database',
        where: 'food_name = ? OR food_name_vi = ? OR food_name_en = ?',
        whereArgs: [normalizedName, foodName, foodName],
        limit: 1,
      );
      
      // If no exact match, try partial match (LIKE)
      if (results.isEmpty) {
        debugPrint('🔍 [NutritionDB] No exact match, trying partial...');
        results = await db.query(
          'nutrition_database',
          where: 'food_name LIKE ? OR food_name_vi LIKE ? OR food_name_en LIKE ?',
          whereArgs: ['%$normalizedName%', '%$foodName%', '%$foodName%'],
          orderBy: 'usage_count DESC', // Prioritize popular foods
          limit: 1,
        );
      }
      
      // If still no match, try first word only (e.g., "Pizza Margherita" → "Pizza")
      if (results.isEmpty) {
        final firstWord = normalizedName.split(' ').first;
        if (firstWord != normalizedName && firstWord.length >= 3) {
          debugPrint('🔍 [NutritionDB] Trying first word: $firstWord');
          results = await db.query(
            'nutrition_database',
            where: 'food_name LIKE ? OR food_name_vi LIKE ? OR food_name_en LIKE ?',
            whereArgs: ['$firstWord%', '$firstWord%', '$firstWord%'],
            orderBy: 'usage_count DESC',
            limit: 1,
          );
        }
      }
      
      if (results.isEmpty) {
        debugPrint('⚠️ [NutritionDB] Not found: $foodName');
        return null;
      }
      
      // Found! Update usage statistics
      final nutritionData = NutritionDataModel.fromMap(results.first);
      await _updateUsageStats(nutritionData.id!);
      
      debugPrint('✅ [NutritionDB] Found: ${nutritionData.foodName} (${nutritionData.caloriesPer100g} cal/100g)');
      
      return nutritionData;
    } catch (e) {
      debugPrint('❌ [NutritionDB] Search error: $e');
      return null;
    }
  }

  /// Save nutrition data to database (cache from API or user input)
  /// 
  /// [nutrition]: Nutrition data to save
  /// 
  /// Returns: true if successful, false otherwise
  /// 
  /// Behavior:
  /// - If food_name exists, UPDATE
  /// - If not exists, INSERT
  /// 
  /// Example:
  /// ```dart
  /// final nutrition = NutritionDataModel(...);
  /// final success = await service.saveNutrition(nutrition);
  /// if (success) {
  ///   print('Saved successfully!');
  /// }
  /// ```
  Future<bool> saveNutrition(NutritionDataModel nutrition) async {
    try {
      debugPrint('💾 [NutritionDB] Saving: ${nutrition.foodName}');
      
      final db = await _db.database;
      
      // Check if exists
      final existing = await db.query(
        'nutrition_database',
        where: 'food_name = ?',
        whereArgs: [nutrition.foodName],
        limit: 1,
      );
      
      if (existing.isNotEmpty) {
        // Update existing
        await db.update(
          'nutrition_database',
          nutrition.copyWith(
            id: existing.first['id'] as int,
            updatedAt: DateTime.now(),
          ).toMap(),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
        debugPrint('✅ [NutritionDB] Updated: ${nutrition.foodName}');
      } else {
        // Insert new
        await db.insert(
          'nutrition_database',
          nutrition.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('✅ [NutritionDB] Inserted: ${nutrition.foodName}');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ [NutritionDB] Save error: $e');
      return false;
    }
  }

  /// Get most used foods (for suggestions)
  /// 
  /// [limit]: Maximum number of results (default: 10)
  /// 
  /// Returns: List of most frequently used foods
  /// 
  /// Example:
  /// ```dart
  /// final popular = await service.getMostUsedFoods(limit: 5);
  /// for (var food in popular) {
  ///   print('${food.foodNameVi}: ${food.usageCount} times');
  /// }
  /// ```
  Future<List<NutritionDataModel>> getMostUsedFoods({int limit = 10}) async {
    try {
      debugPrint('📊 [NutritionDB] Getting most used foods (limit: $limit)');
      
      final db = await _db.database;
      final results = await db.query(
        'nutrition_database',
        orderBy: 'usage_count DESC',
        limit: limit,
      );
      
      final foods = results.map((map) => NutritionDataModel.fromMap(map)).toList();
      
      debugPrint('✅ [NutritionDB] Found ${foods.length} popular foods');
      
      return foods;
    } catch (e) {
      debugPrint('❌ [NutritionDB] Get most used error: $e');
      return [];
    }
  }

  /// Get all nutrition data (for debugging/export)
  Future<List<NutritionDataModel>> getAllNutrition() async {
    try {
      final db = await _db.database;
      final results = await db.query('nutrition_database');
      return results.map((map) => NutritionDataModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [NutritionDB] Get all error: $e');
      return [];
    }
  }

  /// Delete nutrition data by ID
  Future<bool> deleteNutrition(int id) async {
    try {
      final db = await _db.database;
      await db.delete(
        'nutrition_database',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('✅ [NutritionDB] Deleted nutrition ID: $id');
      return true;
    } catch (e) {
      debugPrint('❌ [NutritionDB] Delete error: $e');
      return false;
    }
  }

  /// Clear all nutrition data (for testing)
  Future<void> clearAll() async {
    try {
      final db = await _db.database;
      await db.delete('nutrition_database');
      debugPrint('✅ [NutritionDB] Cleared all nutrition data');
    } catch (e) {
      debugPrint('❌ [NutritionDB] Clear error: $e');
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Normalize food name for better matching
  /// 
  /// - Convert to lowercase
  /// - Trim whitespace
  /// - Remove common prefixes (bánh, món, etc.)
  /// - Remove accents for Vietnamese
  /// 
  /// Example:
  /// "Bánh Pizza Pepperoni" → "pizza pepperoni"
  /// "Phở Bò " → "pho bo"
  String _normalizeFoodName(String name) {
    String normalized = name.toLowerCase().trim();
    
    // Remove common Vietnamese prefixes
    final prefixes = ['bánh', 'món', 'cơm', 'bún', 'phở', 'mì'];
    for (var prefix in prefixes) {
      if (normalized.startsWith('$prefix ')) {
        normalized = normalized.substring(prefix.length + 1).trim();
      }
    }
    
    // Remove accents (Vietnamese diacritics)
    normalized = _removeVietnameseAccents(normalized);
    
    return normalized;
  }

  /// Remove Vietnamese accents for better matching
  /// 
  /// Example: "phở" → "pho", "bánh" → "banh"
  String _removeVietnameseAccents(String text) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const english =    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    
    String result = text;
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], english[i]);
    }
    return result;
  }

  /// Update usage statistics when food is found
  /// 
  /// Increments usage_count and updates last_used timestamp
  Future<void> _updateUsageStats(int id) async {
    try {
      final db = await _db.database;
      await db.rawUpdate('''
        UPDATE nutrition_database 
        SET usage_count = usage_count + 1,
            last_used = ?
        WHERE id = ?
      ''', [DateTime.now().toIso8601String(), id]);
    } catch (e) {
      debugPrint('⚠️ [NutritionDB] Update usage stats error: $e');
      // Don't throw - this is not critical
    }
  }
}

