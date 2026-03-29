// Haptic Feedback Helper
// 
// Provides haptic feedback for better user experience
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Haptic feedback helper
class HapticHelper {
  HapticHelper._();
  
  /// Light impact - for subtle feedback (button taps, toggles)
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ HapticHelper: Light impact failed: $e');
      }
    }
  }
  
  /// Medium impact - for moderate feedback (selection changes)
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ HapticHelper: Medium impact failed: $e');
      }
    }
  }
  
  /// Heavy impact - for strong feedback (important actions, errors)
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ HapticHelper: Heavy impact failed: $e');
      }
    }
  }
  
  /// Selection click - for picker/selector changes
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ HapticHelper: Selection click failed: $e');
      }
    }
  }
  
  /// Vibrate - for notifications or alerts
  static Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ HapticHelper: Vibrate failed: $e');
      }
    }
  }
  
  /// Success feedback - combination of impacts for success feeling
  static Future<void> success() async {
    await lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await lightImpact();
  }
  
  /// Error feedback - combination of impacts for error feeling
  static Future<void> error() async {
    await heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await mediumImpact();
  }
  
  /// Button tap feedback
  static Future<void> buttonTap() async {
    await lightImpact();
  }
  
  /// Delete action feedback
  static Future<void> delete() async {
    await mediumImpact();
  }
  
  /// Save action feedback
  static Future<void> save() async {
    await success();
  }
  
  /// Cancel action feedback
  static Future<void> cancel() async {
    await lightImpact();
  }
  
  /// Navigation feedback
  static Future<void> navigation() async {
    await selectionClick();
  }
}

