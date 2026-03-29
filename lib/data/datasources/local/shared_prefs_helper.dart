import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences Helper
class SharedPrefsHelper {
  static const String _keyFirstTime = 'is_first_time';
  static const String _keyUserId = 'user_id';
  static const String _keyFirebaseUid = 'firebase_uid'; // NEW: Firebase UID for data isolation
  static const String _keyThemeMode = 'theme_mode';

  /// Check if first time opening app
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstTime) ?? true;
  }

  /// Set first time to false
  static Future<void> setNotFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstTime, false);
  }

  /// Save user ID
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  /// Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  /// Clear user ID (logout)
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }

  /// Save theme mode
  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  /// Get theme mode
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'light';
  }

  /// Save Firebase UID (for data isolation)
  static Future<void> saveFirebaseUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFirebaseUid, uid);
  }

  /// Get Firebase UID
  static Future<String?> getFirebaseUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFirebaseUid);
  }

  /// Clear Firebase UID
  static Future<void> clearFirebaseUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirebaseUid);
  }

  /// Clear all user-specific data (on sign out)
  /// 
  /// IMPORTANT: This does NOT clear app preferences like:
  /// - _keyFirstTime (onboarding status)
  /// - _keyThemeMode (user's theme preference)
  /// 
  /// Only clears user-specific data:
  /// - _keyUserId (local user ID)
  /// - _keyFirebaseUid (Firebase authentication UID)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear user-specific data only
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyFirebaseUid);
    
    // DON'T clear app preferences:
    // - _keyFirstTime (user has already seen onboarding)
    // - _keyThemeMode (user's theme preference should persist)
  }
}

