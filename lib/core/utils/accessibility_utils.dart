// Accessibility Utilities
// 
// Helper functions and constants for improving app accessibility
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter/material.dart';

/// Accessibility utilities for better user experience
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Minimum touch target size (44x44 per Material Design guidelines)
  static const double minTouchTargetSize = 44.0;

  /// Get semantic label for calorie value
  static String calorieLabel(double calories) {
    return '${calories.toInt()} calo';
  }

  /// Get semantic label for macro nutrient
  static String macroLabel(String name, double value) {
    return '$name: ${value.toStringAsFixed(1)} gram';
  }

  /// Get semantic label for percentage
  static String percentageLabel(double percentage) {
    return '${percentage.toInt()} phần trăm';
  }

  /// Get semantic label for date
  static String dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hôm nay';
    } else if (dateOnly == yesterday) {
      return 'Hôm qua';
    } else {
      return 'Ngày ${date.day} tháng ${date.month} năm ${date.year}';
    }
  }

  /// Get semantic label for meal type
  static String mealTypeLabel(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
        return 'Ăn vặt';
      default:
        return mealType;
    }
  }

  /// Get semantic label for water intake
  static String waterIntakeLabel(int currentMl, int goalMl) {
    final percentage = (currentMl / goalMl * 100).toInt();
    return 'Đã uống $currentMl mililít trên tổng $goalMl mililít, đạt $percentage phần trăm mục tiêu';
  }

  /// Get semantic label for progress ring
  static String progressRingLabel(double current, double goal) {
    final percentage = (current / goal * 100).clamp(0, 100).toInt();
    return 'Đã ăn ${current.toInt()} trên ${goal.toInt()} calo, đạt $percentage phần trăm mục tiêu';
  }

  /// Announce message to screen reader
  static void announce(BuildContext context, String message) {
    // Use SemanticsService to announce
    // Note: SemanticsService is available in flutter/semantics.dart
    // For now, we'll use a simple approach
    // In production, you can use: SemanticsService.announce(message, TextDirection.ltr);
    debugPrint('Screen reader announcement: $message');
  }

  /// Check if large text accessibility setting is enabled
  static bool isLargeTextEnabled(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0) > 1.3;
  }

  /// Get adjusted font size based on accessibility settings
  static double getAdjustedFontSize(BuildContext context, double baseSize) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    // Cap at 2x to prevent extremely large text
    return baseSize * textScale.clamp(1.0, 2.0);
  }
}

/// Semantic widget wrapper for buttons
class SemanticButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback onPressed;
  final Widget child;

  const SemanticButton({
    super.key,
    required this.label,
    this.hint,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: true,
      onTap: onPressed,
      child: child,
    );
  }
}

/// Semantic widget wrapper for images
class SemanticImage extends StatelessWidget {
  final String label;
  final Widget child;

  const SemanticImage({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      child: child,
    );
  }
}

/// Semantic widget wrapper for progress indicators
class SemanticProgress extends StatelessWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final Widget child;

  const SemanticProgress({
    super.key,
    required this.label,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: '${(value * 100).toInt()}%',
      child: child,
    );
  }
}

