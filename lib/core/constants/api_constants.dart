/// API Constants
class ApiConstants {
  ApiConstants._();

  // Edamam API
  static const String edamamBaseUrl = 'https://api.edamam.com/api';
  static const String edamamNutritionEndpoint = '/nutrition-data';
  static const String edamamFoodDatabaseEndpoint = '/food-database/v2/parser';
  
  // OpenAI API
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiChatEndpoint = '/chat/completions';
  static const String openAiModel = 'gpt-4o'; // or 'gpt-4-turbo'
  
  // Timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static const String contentTypeJson = 'application/json';
  static const String acceptJson = 'application/json';
}

