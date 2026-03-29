/// Environment Configuration
/// 
/// IMPORTANT: 
/// 1. Create a .env file in project root
/// 2. Add your GPT-5 API key:
///    OPENAI_API_KEY=sk-proj-your-actual-key-here
/// 3. Never commit .env to git!
/// 
/// This file reads from .env using flutter_dotenv package
class EnvConfig {
  // Singleton
  static final EnvConfig _instance = EnvConfig._internal();
  static EnvConfig get instance => _instance;
  EnvConfig._internal();

  /// OpenAI GPT-5 API Key
  /// 
  /// Get your API key from: https://platform.openai.com/api-keys
  /// 
  /// ⚠️ PASTE YOUR API KEY HERE (temporary solution):
  /// Replace 'your-gpt5-api-key-here' with your actual key
  static const String openAiApiKey = 'your-gpt5-api-key-here';

  /// OpenAI Model (GPT-4O - optimized for vision, faster than GPT-5)
  static const String openAiModel = 'gpt-4o';

  /// OpenAI API URL
  static const String openAiApiUrl = 'https://api.openai.com/v1/chat/completions';

  /// API Timeout (seconds)
  static const int apiTimeoutSeconds = 30;

  /// Max retry attempts
  static const int maxRetries = 3;

  /// Max completion tokens (GPT-4O is faster and doesn't need as many tokens)
  static const int maxCompletionTokens = 500;

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
        'Please add your GPT-5 API key in:\n'
        'lib/core/config/env_config.dart\n\n'
        'Replace:\n'
        '  static const String openAiApiKey = \'your-gpt5-api-key-here\';\n\n'
        'With:\n'
        '  static const String openAiApiKey = \'sk-proj-YOUR-ACTUAL-KEY\';\n'
      );
    }
    return openAiApiKey;
  }

  // ============================================
  // USDA FoodData Central API Configuration
  // ============================================
  
  /// USDA API Key
  /// 
  /// Get your API key from: https://fdc.nal.usda.gov/api-key-signup.html
  /// 
  /// ⚠️ PASTE YOUR API KEY HERE:
  static const String usdaApiKey = 'your-usda-api-key-here';

  /// USDA API Base URL
  static const String usdaApiUrl = 'https://api.nal.usda.gov/fdc/v1';

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
        'Please add your USDA API key in:\n'
        'lib/core/config/env_config.dart\n'
      );
    }
    return usdaApiKey;
  }
}

