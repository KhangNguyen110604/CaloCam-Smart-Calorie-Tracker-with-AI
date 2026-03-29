import 'package:flutter/foundation.dart';
import '../models/nutrition_data_model.dart';
import '../services/nutrition_database_service.dart';
import '../services/usda_api_service.dart';

/// Nutrition Repository
/// 
/// ORCHESTRATOR - Coordinates between 3 layers:
/// 1. Local Database (fast, offline)
/// 2. USDA API (online, free 1K calls/hour)
/// 3. Manual Input (fallback - handled by UI)
/// 
/// This is the MAIN entry point for nutrition lookup.
/// All nutrition queries should go through this repository.
/// 
/// Usage:
/// ```dart
/// final repo = NutritionRepository.instance;
/// final result = await repo.getNutrition('Phở bò', grams: 500);
/// if (result != null) {
///   print('Calories: ${result['calories']} kcal');
///   print('Source: ${result['source']}'); // 'local' or 'api'
/// } else {
///   // Show manual input dialog
/// }
/// ```
class NutritionRepository {
  // Singleton pattern
  static final NutritionRepository _instance = NutritionRepository._internal();
  static NutritionRepository get instance => _instance;
  NutritionRepository._internal();

  final NutritionDatabaseService _localDb = NutritionDatabaseService.instance;
  final UsdaApiService _api = UsdaApiService.instance;

  /// Get nutrition data for a food item
  /// 
  /// [foodName]: Food name (Vietnamese or English)
  /// [grams]: Portion size in grams (optional, defaults to 100g)
  /// 
  /// Returns: Map with nutrition data or null if not found
  /// 
  /// Flow:
  /// 1. Try local database first (fastest)
  /// 2. If not found, try FatSecret API
  /// 3. If found in API, cache to local database
  /// 4. If still not found, return null (manual input needed)
  /// 
  /// Example:
  /// ```dart
  /// final result = await repo.getNutrition('Phở bò', grams: 500);
  /// if (result != null) {
  ///   print('Calories: ${result['calories']} kcal');
  ///   print('Protein: ${result['protein']}g');
  ///   print('Source: ${result['source']}'); // 'local' or 'api'
  ///   print('Data Source: ${result['data_source']}'); // 'manual', 'fatsecret', etc.
  /// } else {
  ///   // Show manual input dialog to user
  /// }
  /// ```
  Future<Map<String, dynamic>?> getNutrition(
    String foodName, {
    double? grams,
  }) async {
    try {
      debugPrint('🔍 [NutritionRepo] Looking up: $foodName (${grams ?? 100}g)');

      // LAYER 1: Try local database first
      debugPrint('📂 [NutritionRepo] Checking local database...');
      NutritionDataModel? nutrition = await _localDb.searchByName(foodName);
      
      if (nutrition != null) {
        debugPrint('✅ [NutritionRepo] Found in local DB');
        return _buildResult(nutrition, grams, source: 'local');
      }

      // LAYER 2: Try USDA API
      debugPrint('🌐 [NutritionRepo] Not in local, trying USDA API...');
      
      // Try original name first
      debugPrint('🌐 [NutritionRepo] Searching API with original name: $foodName');
      nutrition = await _api.searchFood(foodName);
      
      // If not found and name is Vietnamese, try English translation
      if (nutrition == null && _isVietnamese(foodName)) {
        final englishName = _translateToEnglish(foodName);
        if (englishName != null) {
          debugPrint('🌐 [NutritionRepo] Original not found, trying English: $englishName');
          nutrition = await _api.searchFood(englishName);
        } else {
          debugPrint('⚠️ [NutritionRepo] Vietnamese name detected but no translation found');
        }
      } else if (nutrition == null) {
        debugPrint('⚠️ [NutritionRepo] Not found in API and not Vietnamese');
      }
      
      if (nutrition != null) {
        debugPrint('✅ [NutritionRepo] Found from API, caching...');
        
        // Cache to local database for next time
        await _localDb.saveNutrition(nutrition);
        
        return _buildResult(nutrition, grams, source: 'api');
      }

      // LAYER 3: Not found - manual input needed
      debugPrint('⚠️ [NutritionRepo] Not found anywhere, manual input needed');
      return null;

    } catch (e) {
      debugPrint('❌ [NutritionRepo] Error: $e');
      return null;
    }
  }

  /// Save user-contributed nutrition data
  /// 
  /// When user manually inputs nutrition, save it for future use.
  /// This helps build a crowdsourced nutrition database.
  /// 
  /// [foodName]: Food name
  /// [caloriesPer100g]: Calories per 100g
  /// [protein]: Protein per 100g (optional)
  /// [carbs]: Carbs per 100g (optional)
  /// [fat]: Fat per 100g (optional)
  /// 
  /// Returns: true if saved successfully
  /// 
  /// Example:
  /// ```dart
  /// final success = await repo.saveUserContribution(
  ///   'Bánh mì chả lụa',
  ///   caloriesPer100g: 250,
  ///   protein: 8,
  ///   carbs: 35,
  ///   fat: 8,
  /// );
  /// if (success) {
  ///   print('Thank you for contributing!');
  /// }
  /// ```
  Future<bool> saveUserContribution(
    String foodName,
    double caloriesPer100g, {
    double? protein,
    double? carbs,
    double? fat,
    String? foodNameVi,
    String? foodNameEn,
  }) async {
    try {
      debugPrint('💾 [NutritionRepo] Saving user contribution: $foodName');
      
      final nutrition = NutritionDataModel(
        foodName: _normalizeFoodName(foodName),
        foodNameVi: foodNameVi ?? foodName,
        foodNameEn: foodNameEn,
        caloriesPer100g: caloriesPer100g,
        proteinPer100g: protein ?? 0,
        carbsPer100g: carbs ?? 0,
        fatPer100g: fat ?? 0,
        source: 'user',
        isVerified: false, // User contributions need verification
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final success = await _localDb.saveNutrition(nutrition);
      
      if (success) {
        debugPrint('✅ [NutritionRepo] User contribution saved');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [NutritionRepo] Save user contribution error: $e');
      return false;
    }
  }

  /// Get most used foods (for suggestions)
  /// 
  /// Returns list of frequently used foods for quick access.
  /// 
  /// [limit]: Maximum number of results (default: 10)
  /// 
  /// Example:
  /// ```dart
  /// final popular = await repo.getMostUsedFoods(limit: 5);
  /// for (var food in popular) {
  ///   print('${food['food_name']}: ${food['usage_count']} times');
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getMostUsedFoods({int limit = 10}) async {
    try {
      final foods = await _localDb.getMostUsedFoods(limit: limit);
      return foods.map((food) => {
        'id': food.id,
        'food_name': food.foodNameVi ?? food.foodName,
        'food_name_en': food.foodNameEn,
        'calories_per_100g': food.caloriesPer100g,
        'usage_count': food.usageCount,
        'source': food.source,
      }).toList();
    } catch (e) {
      debugPrint('❌ [NutritionRepo] Get most used error: $e');
      return [];
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Build result map with calculated nutrition
  /// 
  /// [nutrition]: Nutrition data model
  /// [grams]: Portion size in grams
  /// [source]: Where the data came from ('local' or 'api')
  /// 
  /// Returns: Map with all nutrition info
  Map<String, dynamic> _buildResult(
    NutritionDataModel nutrition,
    double? grams,
    {required String source}
  ) {
    final portionGrams = grams ?? 100.0;
    final calculated = nutrition.calculateForPortion(portionGrams);
    
    return {
      // Food info
      'food_name': nutrition.foodNameVi ?? nutrition.foodName,
      'food_name_en': nutrition.foodNameEn,
      'food_name_vi': nutrition.foodNameVi,
      
      // Calculated nutrition for portion
      'calories': calculated['calories']!,
      'protein': calculated['protein']!,
      'carbs': calculated['carbs']!,
      'fat': calculated['fat']!,
      'fiber': calculated['fiber'],
      
      // Portion info
      'portion_grams': portionGrams,
      'portion_size': _formatPortionSize(portionGrams),
      
      // Metadata
      'source': source,              // 'local' or 'api' (where we got it from)
      'data_source': nutrition.source, // 'manual', 'fatsecret', 'user' (original source)
      'is_verified': nutrition.isVerified,
      
      // Serving sizes (if available)
      'serving_sizes': nutrition.servingSizes?.map((s) => {
        'name': s.name,
        'grams': s.grams,
      }).toList(),
    };
  }

  /// Format portion size for display
  /// 
  /// Example:
  /// - 100g → "100g"
  /// - 500g → "500g"
  /// - 1000g → "1kg"
  String _formatPortionSize(double grams) {
    if (grams >= 1000) {
      return '${(grams / 1000).toStringAsFixed(1)}kg';
    }
    return '${grams.toStringAsFixed(0)}g';
  }

  /// Normalize food name for consistency
  String _normalizeFoodName(String name) {
    return name.toLowerCase().trim();
  }

  /// Check if food name is Vietnamese
  /// 
  /// Simple heuristic: Check for Vietnamese-specific characters
  bool _isVietnamese(String name) {
    // Vietnamese-specific characters: ă, â, đ, ê, ô, ơ, ư, and tones
    final vietnamesePattern = RegExp(r'[ăâđêôơưáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]');
    return vietnamesePattern.hasMatch(name.toLowerCase());
  }

  /// Translate common Vietnamese food names to English
  /// 
  /// This is a simple lookup table for common foods.
  /// For better results, integrate a translation API.
  String? _translateToEnglish(String vietnameseName) {
    final translations = <String, String>{
      // Common Vietnamese foods
      'phở': 'pho',
      'phở bò': 'beef pho',
      'phở gà': 'chicken pho',
      'bún': 'vermicelli',
      'bún bò': 'beef vermicelli',
      'bún chả': 'grilled pork vermicelli',
      'bánh mì': 'banh mi',
      'bánh mì thịt': 'pork banh mi',
      'bánh mì chả': 'vietnamese sandwich',
      'cơm': 'rice',
      'cơm tấm': 'broken rice',
      'cơm sườn': 'pork chop rice',
      'gỏi cuốn': 'spring roll',
      'chả giò': 'fried spring roll',
      'nem': 'spring roll',
      'bánh xèo': 'vietnamese pancake',
      'bánh cuốn': 'steamed rice roll',
      'hủ tiếu': 'hu tieu noodle',
      'mì quảng': 'quang noodle',
      'cao lầu': 'cao lau noodle',
      'bánh canh': 'thick noodle soup',
      'bún riêu': 'crab noodle soup',
      'bún bò huế': 'hue beef noodle',
      'canh chua': 'sour soup',
      'lẩu': 'hot pot',
      'gà': 'chicken',
      'bò': 'beef',
      'heo': 'pork',
      'cá': 'fish',
      'tôm': 'shrimp',
      'mực': 'squid',
      'rau': 'vegetable',
      'trứng': 'egg',
      'sữa': 'milk',
      'cà phê': 'coffee',
      'trà': 'tea',
      'nước': 'water',
      'bia': 'beer',
      
      // Western foods (Vietnamese names)
      'pizza': 'pizza',
      'pizza xúc xích': 'pepperoni pizza',
      'pizza hải sản': 'seafood pizza',
      'pizza gà': 'chicken pizza',
      'pizza phô mai': 'cheese pizza',
      'burger': 'burger',
      'hamburger': 'hamburger',
      'gà rán': 'fried chicken',
      'khoai tây chiên': 'french fries',
      'mì ý': 'pasta',
      'mì ý sốt cà chua': 'tomato pasta',
      'mì ý carbonara': 'carbonara pasta',
      'salad': 'salad',
      'sandwich': 'sandwich',
      'hot dog': 'hot dog',
      'bánh ngọt': 'cake',
      'bánh kem': 'cream cake',
      'kem': 'ice cream',
      'sô cô la': 'chocolate',
      'kẹo': 'candy',
    };

    final normalized = vietnameseName.toLowerCase().trim();
    
    // Try exact match first
    if (translations.containsKey(normalized)) {
      return translations[normalized];
    }
    
    // Try partial match (e.g., "pizza xúc xích thập cẩm" → "pizza")
    for (var entry in translations.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }
}

