// Test Helpers
// 
// Provides common utilities and mock data for testing
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart'; // ✅ Added flutter_test
import 'package:provider/provider.dart';
import 'package:calocount_app/presentation/providers/meal_provider.dart';
import 'package:calocount_app/presentation/providers/water_provider.dart';

/// Create a test widget wrapped with necessary providers
/// 
/// This is useful for testing widgets that depend on providers
/// without having to set up the entire app structure
Widget createTestWidget({
  required Widget child,
  MealProvider? mealProvider,
  WaterProvider? waterProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MealProvider>(
        create: (_) => mealProvider ?? MealProvider(),
      ),
      ChangeNotifierProvider<WaterProvider>(
        create: (_) => waterProvider ?? WaterProvider(),
      ),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Create a basic MaterialApp wrapper for simple widget tests
/// 
/// Use this when you don't need providers
Widget createBasicTestWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

/// Wait for all microtasks and timers to complete
/// 
/// Useful for waiting for async operations in tests
Future<void> pumpAndSettle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// Find a widget by text
/// 
/// Helper to find widgets containing specific text
Finder findTextWidget(String text) {
  return find.text(text);
}

/// Find a widget by type
/// 
/// Helper to find widgets by their type
Finder findWidgetByType<T>() {
  return find.byType(T);
}

/// Find a widget by key
/// 
/// Helper to find widgets by their key
Finder findWidgetByKey(Key key) {
  return find.byKey(key);
}

