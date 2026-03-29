import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env_config.dart';
import '../models/nutrition_data_model.dart';

/// USDA FoodData Central API Service
/// 
/// Integrates with USDA FoodData Central API for nutrition lookup.
/// This is the SECOND layer (after local database).
/// 
/// API Documentation: https://fdc.nal.usda.gov/api-guide.html
/// 
/// Features:
/// - Search foods by name
/// - Get detailed nutrition information
/// - No OAuth required (simple API key)
/// - 1,000 requests/hour limit
/// - Works from Vietnam (no IP block)
/// 
/// Usage:
/// ```dart
/// final service = UsdaApiService.instance;
/// final nutrition = await service.searchFood('pizza');
/// if (nutrition != null) {
///   print('Calories: ${nutrition.caloriesPer100g} kcal/100g');
/// }
/// ```
class UsdaApiService {
  // Singleton pattern
  static final UsdaApiService _instance = UsdaApiService._internal();
  static UsdaApiService get instance => _instance;
  UsdaApiService._internal();

  final http.Client _client = http.Client();

  /// Search food nutrition from USDA API
  /// 
  /// [foodName]: Food name to search (English recommended for better results)
  /// 
  /// Returns: NutritionDataModel if found, null otherwise
  /// 
  /// Flow:
  /// 1. Call foods/search endpoint
  /// 2. Get first result
  /// 3. Call food/{fdcId} endpoint for detailed nutrition
  /// 4. Convert to NutritionDataModel
  /// 
  /// Example:
  /// ```dart
  /// final nutrition = await service.searchFood('Pepperoni Pizza');
  /// if (nutrition != null) {
  ///   print('Found from USDA: ${nutrition.caloriesPer100g} kcal/100g');
  ///   print('Source: ${nutrition.source}'); // 'usda'
  /// }
  /// ```
  Future<NutritionDataModel?> searchFood(String foodName) async {
    try {
      debugPrint('🌐 [USDAAPI] Searching: $foodName');

      // Check if API is configured
      if (!EnvConfig.isUsdaConfigured) {
        debugPrint('⚠️ [USDAAPI] API not configured');
        return null;
      }

      // Step 1: Search for food
      final searchUrl = Uri.parse(
        '${EnvConfig.usdaApiUrl}/foods/search'
      ).replace(queryParameters: {
        'api_key': EnvConfig.getUsdaApiKey(),
        'query': foodName,
        'pageSize': '1', // Only get first result
        'dataType': 'Foundation,SR Legacy', // Use high-quality data sources
      });

      debugPrint('🌐 [USDAAPI] Calling search API...');
      
      final searchResponse = await _client.get(searchUrl)
          .timeout(const Duration(seconds: 10));

      debugPrint('🌐 [USDAAPI] Search response status: ${searchResponse.statusCode}');

      if (searchResponse.statusCode != 200) {
        debugPrint('❌ [USDAAPI] HTTP ${searchResponse.statusCode}: ${searchResponse.body}');
        return null;
      }

      final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>;
      
      // Check if foods found
      if (!searchData.containsKey('foods') || searchData['foods'] == null) {
        debugPrint('⚠️ [USDAAPI] No foods found for: $foodName');
        return null;
      }

      final foods = searchData['foods'] as List;
      if (foods.isEmpty) {
        debugPrint('⚠️ [USDAAPI] Empty results for: $foodName');
        return null;
      }

      // Get first food
      final food = foods.first as Map<String, dynamic>;
      final fdcId = food['fdcId'] as int;
      final foodDescription = food['description'] as String? ?? foodName;

      debugPrint('🌐 [USDAAPI] Found food: $foodDescription (ID: $fdcId)');

      // Step 2: Get detailed nutrition
      final detailUrl = Uri.parse(
        '${EnvConfig.usdaApiUrl}/food/$fdcId'
      ).replace(queryParameters: {
        'api_key': EnvConfig.getUsdaApiKey(),
      });

      debugPrint('🌐 [USDAAPI] Getting detailed nutrition...');

      final detailResponse = await _client.get(detailUrl)
          .timeout(const Duration(seconds: 10));

      if (detailResponse.statusCode != 200) {
        debugPrint('❌ [USDAAPI] Detail request failed: ${detailResponse.statusCode}');
        return null;
      }

      final detailData = jsonDecode(detailResponse.body) as Map<String, dynamic>;

      // Parse nutrition data
      final nutrition = _parseNutritionData(detailData, foodDescription);

      if (nutrition != null) {
        debugPrint('✅ [USDAAPI] Found: ${nutrition.foodName}');
        debugPrint('   Calories: ${nutrition.caloriesPer100g} kcal/100g');
        debugPrint('   Protein: ${nutrition.proteinPer100g}g');
        debugPrint('   Carbs: ${nutrition.carbsPer100g}g');
        debugPrint('   Fat: ${nutrition.fatPer100g}g');
      }

      return nutrition;
    } catch (e) {
      debugPrint('❌ [USDAAPI] Search error: $e');
      return null;
    }
  }

  /// Parse USDA nutrition data to NutritionDataModel
  /// 
  /// USDA provides nutrients in a list with nutrient IDs:
  /// - 1008: Energy (kcal)
  /// - 1003: Protein
  /// - 1005: Carbohydrate
  /// - 1004: Total lipid (fat)
  /// - 1079: Fiber
  /// 
  /// All values are per 100g by default in USDA database.
  NutritionDataModel? _parseNutritionData(
    Map<String, dynamic> data,
    String foodName,
  ) {
    try {
      // Get food nutrients
      final foodNutrients = data['foodNutrients'] as List?;
      if (foodNutrients == null || foodNutrients.isEmpty) {
        debugPrint('⚠️ [USDAAPI] No nutrients data');
        return null;
      }

      // Extract nutrition values
      double? calories;
      double? protein;
      double? carbs;
      double? fat;
      double? fiber;

      for (var nutrient in foodNutrients) {
        final nutrientData = nutrient as Map<String, dynamic>;
        final nutrientInfo = nutrientData['nutrient'] as Map<String, dynamic>?;
        
        if (nutrientInfo == null) continue;

        final nutrientId = nutrientInfo['id'] as int?;
        final amount = (nutrientData['amount'] as num?)?.toDouble();

        if (amount == null) continue;

        switch (nutrientId) {
          case 1008: // Energy (kcal)
            calories = amount;
            break;
          case 1003: // Protein
            protein = amount;
            break;
          case 1005: // Carbohydrate
            carbs = amount;
            break;
          case 1004: // Total lipid (fat)
            fat = amount;
            break;
          case 1079: // Fiber
            fiber = amount;
            break;
        }
      }

      // Validate required nutrients
      if (calories == null) {
        debugPrint('⚠️ [USDAAPI] Missing calories data');
        return null;
      }

      return NutritionDataModel(
        foodName: _normalizeFoodName(foodName),
        foodNameEn: foodName,
        caloriesPer100g: calories,
        proteinPer100g: protein ?? 0,
        carbsPer100g: carbs ?? 0,
        fatPer100g: fat ?? 0,
        fiberPer100g: fiber,
        source: 'usda',
        isVerified: true, // USDA data is verified
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [USDAAPI] Parse error: $e');
      return null;
    }
  }

  /// Normalize food name for database storage
  String _normalizeFoodName(String name) {
    return name.toLowerCase().trim();
  }

  /// Dispose HTTP client
  void dispose() {
    _client.close();
  }
}

