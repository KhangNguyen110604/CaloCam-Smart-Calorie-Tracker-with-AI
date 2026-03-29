import 'package:flutter/material.dart';

/// App Colors - Xanh lá chủ đạo (Green & Fresh theme)
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors - Xanh lá
  static const Color primary = Color(0xFF4CAF50); // Green 500
  static const Color primaryLight = Color(0xFF81C784); // Green 300
  static const Color primaryDark = Color(0xFF388E3C); // Green 700
  static const Color primaryVeryLight = Color(0xFFC8E6C9); // Green 100

  // Secondary Colors - Cam (for calories/energy)
  static const Color secondary = Color(0xFFFF9800); // Orange 500
  static const Color secondaryLight = Color(0xFFFFB74D); // Orange 300
  static const Color secondaryDark = Color(0xFFF57C00); // Orange 700

  // Accent Colors - Xanh dương (for water)
  static const Color accent = Color(0xFF2196F3); // Blue 500
  static const Color accentLight = Color(0xFF64B5F6); // Blue 300

  // Semantic Colors
  static const Color success = Color(0xFF66BB6A); // Light Green
  static const Color warning = Color(0xFFFFA726); // Light Orange
  static const Color error = Color(0xFFEF5350); // Red 400
  static const Color info = Color(0xFF42A5F5); // Light Blue

  // Neutral Colors - Light Theme
  static const Color background = Color(0xFFF5F5F5); // Grey 100
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFFAFAFA); // Grey 50

  // Text Colors - Light Theme
  static const Color textPrimary = Color(0xFF212121); // Grey 900
  static const Color textSecondary = Color(0xFF757575); // Grey 600
  static const Color textHint = Color(0xFFBDBDBD); // Grey 400
  static const Color textDisabled = Color(0xFF9E9E9E); // Grey 500

  // Divider
  static const Color divider = Color(0xFFE0E0E0); // Grey 300
  static const Color border = divider;

  // Meal Type Colors
  static const Color breakfast = Color(0xFFFFA726); // Amber/Orange (Morning sun) - Darker for better contrast
  static const Color lunch = Color(0xFFFF9800); // Orange (Noon)
  static const Color dinner = Color(0xFFFF5722); // Deep Orange (Evening)
  static const Color snack = Color(0xFF9C27B0); // Purple (Anytime)

  // Macro Colors
  static const Color protein = Color(0xFFE91E63); // Pink
  static const Color carbs = Color(0xFF2196F3); // Blue
  static const Color fat = Color(0xFFFF9800); // Orange
  static const Color macroProtein = protein;
  static const Color macroCarbs = carbs;
  static const Color macroFat = fat;

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
  ];

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212); // Almost Black
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark Grey
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Light Grey
  static const Color darkDivider = Color(0xFF424242);

  // Goal Colors
  static const Color goalLoseWeight = Color(0xFF2196F3); // Blue (cool down)
  static const Color goalMaintain = Color(0xFF4CAF50); // Green (balanced)
  static const Color goalGainWeight = Color(0xFFFF5722); // Orange (heat up)

  // Status Colors
  static const Color completed = Color(0xFF66BB6A);
  static const Color pending = Color(0xFFBDBDBD);
  static const Color inProgress = Color(0xFFFF9800);

  // Opacity variants
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color secondaryWithOpacity(double opacity) =>
      secondary.withValues(alpha: opacity);
  static Color accentWithOpacity(double opacity) => accent.withValues(alpha: opacity);
}

