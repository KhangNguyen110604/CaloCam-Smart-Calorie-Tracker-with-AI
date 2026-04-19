import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment Configuration
/// 
/// IMPORTANT: 
/// 1. Create a .env file in project root
/// 2. Add your API keys to the .env file.
/// 3. Never commit .env to git!
/// 
/// This file reads from .env using flutter_dotenv package
class EnvConfig {
  // Singleton
  static final EnvConfig _instance = EnvConfig._internal();
  static EnvConfig get instance => _instance;
  EnvConfig._internal();

  /// OpenAI API Key
  static String get openAiApiKey => dotenv.get('OPENAI_API_KEY', fallback: '');

  /// OpenAI Model (GPT-4O - optimized for vision)
  static String get openAiModel => dotenv.get('OPENAI_MODEL', fallback: 'gpt-4o');

  /// OpenAI API URL
  static String get openAiApiUrl => dotenv.get('OPENAI_API_URL', fallback: 'https://api.openai.com/v1/chat/completions');

  /// API Timeout (seconds)
  static final int apiTimeoutSeconds = int.tryParse(dotenv.get('API_TIMEOUT', fallback: '30')) ?? 30;

  /// Max retry attempts
  static final int maxRetries = int.tryParse(dotenv.get('MAX_RETRIES', fallback: '3')) ?? 3;

  /// Max completion tokens
  static final int maxCompletionTokens = int.tryParse(dotenv.get('MAX_COMPLETION_TOKENS', fallback: '500')) ?? 500;

  /// Check if API key is configured
  static bool get isApiKeyConfigured {
    return openAiApiKey.isNotEmpty && 
           openAiApiKey != 'your-gpt5-api-key-here';
  }

  /// Get API key with validation
  static String getApiKey() {
    if (!isApiKeyConfigured) {
      throw Exception(
        'OpenAI API key not configured!\n'
        'Please add your API key in the .env file:\n'
        'OPENAI_API_KEY=sk-proj-YOUR-ACTUAL-KEY'
      );
    }
    return openAiApiKey;
  }

  // ============================================
  // USDA FoodData Central API Configuration
  // ============================================
  
  /// USDA API Key
  static String get usdaApiKey => dotenv.get('USDA_API_KEY', fallback: '');

  /// USDA API Base URL
  static String get usdaApiUrl => dotenv.get('USDA_API_URL', fallback: 'https://api.nal.usda.gov/fdc/v1');

  /// Check if USDA API is configured
  static bool get isUsdaConfigured {
    return usdaApiKey.isNotEmpty && 
           usdaApiKey != 'your-usda-api-key-here';
  }

  /// Get USDA API Key with validation
  static String getUsdaApiKey() {
    if (!isUsdaConfigured) {
      throw Exception(
        'USDA API key not configured!\n'
        'Please add your USDA API key in the .env file:\n'
        'USDA_API_KEY=YOUR-ACTUAL-KEY'
      );
    }
    return usdaApiKey;
  }
}

