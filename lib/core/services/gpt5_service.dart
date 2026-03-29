import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

/// GPT-5 Service - AI Food Recognition
/// 
/// Uses OpenAI GPT-5 Vision API to recognize food from images
/// and extract nutritional information.
/// 
/// Features:
/// - Image to base64 conversion
/// - GPT-5 Vision API integration
/// - Structured JSON response parsing
/// - Error handling and retry logic
/// 
/// Usage:
/// ```dart
/// final service = GPT5Service.instance;
/// final result = await service.recognizeFood(imageFile);
/// print('Food: ${result['food_name']}');
/// print('Calories: ${result['calories']}');
/// ```
class GPT5Service {
  // Singleton pattern
  static final GPT5Service _instance = GPT5Service._internal();
  static GPT5Service get instance => _instance;
  GPT5Service._internal();

  // HTTP client
  final http.Client _client = http.Client();

  /// Convert image file to base64 string
  /// 
  /// Parameters:
  /// - [imageFile]: Image file to convert
  /// 
  /// Returns base64 encoded string or null if error
  Future<String?> _imageToBase64(File imageFile) async {
    try {
      debugPrint('📸 GPT5Service: Converting image to base64...');
      
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      final double sizeMB = imageBytes.length / 1024 / 1024;
      debugPrint('✅ GPT5Service: Image encoded (${sizeMB.toStringAsFixed(2)} MB)');
      
      return base64Image;
    } catch (e) {
      debugPrint('❌ GPT5Service: Image encoding error: $e');
      return null;
    }
  }

  /// Build prompt for GPT-4 Vision
  /// 
  /// ⚠️ IMPORTANT CHANGE: GPT-4 now ONLY recognizes food items.
  /// DO NOT ask GPT-4 to calculate calories!
  /// Calories will be looked up from database/API separately.
  String _buildPrompt() {
    return '''
You are a food recognition expert. Analyze this image and identify the food items.

CRITICAL INSTRUCTIONS:
1. Identify ALL food items in the image
2. Use STANDARDIZED food names (consistent naming is crucial for database lookup)
3. For each item, provide:
   - Food name (Vietnamese AND English)
   - Quantity (exact count: 1 cái, 2 miếng, 3 xiên, etc.)
   - Size description (DETAILED: Tô lớn, Bát nhỏ, Đĩa vừa, 1 ổ bánh mì, etc.)
   - Estimated weight in grams (calculate from quantity × size)
   - Confidence score (0.0 to 1.0)

QUANTITY & SIZE ESTIMATION (VERY IMPORTANT):
- Count EXACT number of items (1 cái, 2 miếng, 3 xiên, 1 tô, 1 đĩa, etc.)
- Describe SIZE accurately:
  * For bowls/plates: Tô nhỏ (300g), Tô vừa (400g), Tô lớn (500g), Bát (250g), Đĩa (300-400g)
  * For bread: 1 ổ bánh mì (200g), 1 miếng bánh (80g)
  * For pizza: 1 miếng (100g), Bánh nhỏ 6" (300g), Bánh vừa 9" (600g), Bánh lớn 12" (900g)
  * For meat: 1 miếng nhỏ (80g), 1 miếng vừa (100g), 1 miếng lớn (150g)
  * For rice: 1 bát (150g), 1 đĩa (200g)
- Calculate estimated_grams = quantity × typical_size_in_grams
- Be PRECISE with measurements based on visual size

NAMING RULES (VERY IMPORTANT):
- Use SIMPLE, COMMON names (e.g., "Pizza" not "Bánh Pizza", "Burger" not "Bánh Burger")
- For Vietnamese food: Keep traditional names (e.g., "Phở bò", "Bún chả", "Cơm tấm")
- For Western food: Use English names directly (e.g., "Pizza Pepperoni", "Fried Chicken", "Burger")
- Be CONSISTENT: Always use the same name for the same food type
- Remove unnecessary prefixes like "Bánh", "Món" for Western foods

DO NOT calculate calories or nutrition values!
Only identify the food items and estimate their size/weight ACCURATELY.

Return ONLY valid JSON, no markdown or extra text.

Required JSON format:
{
  "foods": [
    {
      "name_vi": "Simple Vietnamese name",
      "name_en": "Simple English name",
      "quantity": 1,
      "size": "DETAILED size description with unit",
      "estimated_grams": 500,
      "confidence": 0.95
    }
  ]
}

EXAMPLES (CORRECT FORMAT):
✅ Pizza (1 miếng):
{
  "name_vi": "Pizza Pepperoni",
  "name_en": "Pepperoni Pizza",
  "quantity": 1,
  "size": "1 miếng pizza lớn",
  "estimated_grams": 120,
  "confidence": 0.95
}

✅ Phở (1 tô):
{
  "name_vi": "Phở bò",
  "name_en": "Beef Pho",
  "quantity": 1,
  "size": "Tô lớn",
  "estimated_grams": 500,
  "confidence": 0.95
}

✅ Bánh mì (1 ổ):
{
  "name_vi": "Bánh mì thịt",
  "name_en": "Vietnamese Sandwich",
  "quantity": 1,
  "size": "1 ổ bánh mì",
  "estimated_grams": 200,
  "confidence": 0.95
}

✅ Gà rán (3 miếng):
{
  "name_vi": "Gà rán",
  "name_en": "Fried Chicken",
  "quantity": 3,
  "size": "3 miếng gà (đùi, cánh, ức)",
  "estimated_grams": 300,
  "confidence": 0.95
}

❌ WRONG: "size": "Lớn" (too vague, should be "Tô lớn" or "Đĩa lớn")
❌ WRONG: "quantity": 1, "estimated_grams": 50 (too small for 1 portion)
❌ WRONG: "Bánh Pizza Pepperoni" (remove "Bánh" prefix for Western food)

If multiple items on the same plate, include ALL in the "foods" array with separate entries.

Example response for multiple items:
{
  "foods": [
    {
      "name_vi": "Cơm tấm",
      "name_en": "Broken Rice",
      "quantity": 1,
      "size": "1 đĩa cơm",
      "estimated_grams": 200,
      "confidence": 0.95
    },
    {
      "name_vi": "Sườn nướng",
      "name_en": "Grilled Pork Ribs",
      "quantity": 2,
      "size": "2 miếng sườn",
      "estimated_grams": 200,
      "confidence": 0.90
    }
  ]
}
''';
  }

  /// Recognize food from image using GPT-4 Vision API
  /// 
  /// ⚠️ CHANGED: Now returns list of recognized foods WITHOUT nutrition data.
  /// Nutrition lookup will be done separately using NutritionRepository.
  /// 
  /// Parameters:
  /// - [imageFile]: Image file containing food
  /// 
  /// Returns:
  /// - List of recognized foods with metadata (name, quantity, size, estimated_grams)
  /// - null if error occurred
  /// 
  /// Example:
  /// ```dart
  /// final foods = await GPT5Service.instance.recognizeFood(imageFile);
  /// if (foods != null && foods.isNotEmpty) {
  ///   for (var food in foods) {
  ///     print('Detected: ${food['name_vi']}');
  ///     print('Estimated: ${food['estimated_grams']}g');
  ///     // Lookup nutrition separately using NutritionRepository
  ///   }
  /// }
  /// ```
  Future<List<Map<String, dynamic>>?> recognizeFood(File imageFile) async {
    try {
      debugPrint('🤖 GPT5Service: Starting food recognition...');

      // Validate API key
      if (!EnvConfig.isApiKeyConfigured) {
        throw Exception('API key not configured');
      }

      // Convert image to base64
      final String? base64Image = await _imageToBase64(imageFile);
      if (base64Image == null) {
        throw Exception('Failed to encode image');
      }

      // Build request
      final Map<String, dynamic> requestBody = {
        'model': EnvConfig.openAiModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': _buildPrompt(),
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                  'detail': 'high', // High detail for better recognition
                },
              },
            ],
          },
        ],
        'max_completion_tokens': EnvConfig.maxCompletionTokens, // GPT-4O is faster and more efficient
        // Note: Temperature omitted to use default value
      };

      debugPrint('📡 GPT5Service: Sending request to OpenAI...');

      // Send request
      final response = await _client
          .post(
            Uri.parse(EnvConfig.openAiApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${EnvConfig.getApiKey()}',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            Duration(seconds: EnvConfig.apiTimeoutSeconds),
          );

      debugPrint('📡 GPT5Service: Response status: ${response.statusCode}');
      debugPrint('📡 GPT5Service: Response body length: ${response.body.length}');

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception('API error: ${errorBody['error']['message']}');
      }

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Debug: Print full response structure
      debugPrint('📊 GPT5Service: Response keys: ${responseData.keys.toList()}');
      debugPrint('📊 GPT5Service: Full response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
      // Try to get content from different possible paths
      String? content;
      
      // Try standard path
      if (responseData.containsKey('choices') && 
          responseData['choices'] is List && 
          (responseData['choices'] as List).isNotEmpty) {
        final choice = responseData['choices'][0];
        if (choice.containsKey('message') && choice['message'].containsKey('content')) {
          content = choice['message']['content'];
        }
      }
      
      // Try alternative path for streaming responses
      if (content == null && responseData.containsKey('data')) {
        content = responseData['data'].toString();
      }

      if (content == null || content.isEmpty) {
        throw Exception('Empty response from API. Response: ${response.body}');
      }

      debugPrint('📝 GPT5Service: Raw response: $content');

      // Parse JSON from response
      // Remove markdown code blocks if present
      String jsonString = content.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.substring(7);
      }
      if (jsonString.startsWith('```')) {
        jsonString = jsonString.substring(3);
      }
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3);
      }
      jsonString = jsonString.trim();

      final Map<String, dynamic> result = json.decode(jsonString);

      // Validate required fields (new format)
      if (!result.containsKey('foods') || result['foods'] is! List) {
        throw Exception('Invalid response format: missing foods array');
      }

      final List<dynamic> foodsList = result['foods'];
      
      if (foodsList.isEmpty) {
        debugPrint('⚠️ GPT5Service: No foods detected in image');
        return [];
      }

      // Convert to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> recognizedFoods = [];
      
      for (var food in foodsList) {
        if (food is! Map<String, dynamic>) continue;
        
        // Ensure required fields exist
        if (!food.containsKey('name_vi') && !food.containsKey('name_en')) {
          debugPrint('⚠️ GPT5Service: Skipping food without name');
          continue;
        }
        
        // Ensure numeric types
        recognizedFoods.add({
          'name_vi': food['name_vi'] as String?,
          'name_en': food['name_en'] as String?,
          'quantity': (food['quantity'] as num?)?.toInt() ?? 1,
          'size': food['size'] as String? ?? 'Không xác định',
          'estimated_grams': (food['estimated_grams'] as num?)?.toDouble() ?? 100.0,
          'confidence': (food['confidence'] as num?)?.toDouble() ?? 0.8,
        });
      }

      debugPrint('✅ GPT5Service: Recognition successful!');
      debugPrint('   Detected ${recognizedFoods.length} food(s):');
      for (var food in recognizedFoods) {
        debugPrint('   - ${food['name_vi'] ?? food['name_en']} (${food['estimated_grams']}g, ${(food['confidence'] * 100).toStringAsFixed(0)}%)');
      }

      return recognizedFoods;
    } on TimeoutException {
      debugPrint('❌ GPT5Service: Request timeout');
      return null;
    } catch (e) {
      debugPrint('❌ GPT5Service: Recognition error: $e');
      return null;
    }
  }

  /// Recognize food with retry logic
  /// 
  /// Automatically retries on failure up to maxRetries times.
  /// 
  /// ⚠️ CHANGED: Now returns list of recognized foods WITHOUT nutrition data.
  /// 
  /// Parameters:
  /// - [imageFile]: Image file containing food
  /// - [maxRetries]: Maximum retry attempts (default: 3)
  /// 
  /// Returns list of recognized foods or null if all retries failed
  Future<List<Map<String, dynamic>>?> recognizeFoodWithRetry(
    File imageFile, {
    int? maxRetries,
  }) async {
    final int retries = maxRetries ?? EnvConfig.maxRetries;

    for (int attempt = 1; attempt <= retries; attempt++) {
      debugPrint('🔄 GPT5Service: Attempt $attempt/$retries');

      final result = await recognizeFood(imageFile);

      if (result != null && result.isNotEmpty) {
        return result;
      }

      if (attempt < retries) {
        // Wait before retry (exponential backoff)
        final int waitSeconds = attempt * 2;
        debugPrint('⏳ GPT5Service: Waiting ${waitSeconds}s before retry...');
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }

    debugPrint('❌ GPT5Service: All retry attempts failed');
    return null;
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

