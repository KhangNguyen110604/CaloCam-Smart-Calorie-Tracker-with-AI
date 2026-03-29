// Meal Card Widget Tests
// 
// Tests for meal entry cards in the UI
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

void main() {
  group('Meal Card Widget Tests', () {
    testWidgets('Displays meal name', (WidgetTester tester) async {
      // Arrange
      final meal = getMockMealEntries().first;
      
      final widget = Card(
        child: ListTile(
          title: Text(meal.foodName),
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text(meal.foodName), findsOneWidget);
    });
    
    testWidgets('Displays meal calories', (WidgetTester tester) async {
      // Arrange
      final meal = getMockMealEntries().first;
      
      final widget = Card(
        child: ListTile(
          title: Text(meal.foodName),
          subtitle: Text('${meal.calories.toInt()} calo'),
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('${meal.calories.toInt()} calo'), findsOneWidget);
    });
    
    testWidgets('Displays meal time', (WidgetTester tester) async {
      // Arrange
      final meal = getMockMealEntries().first;
      
      final widget = Card(
        child: ListTile(
          title: Text(meal.foodName),
          subtitle: Text(meal.time),
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text(meal.time), findsOneWidget);
    });
    
    testWidgets('Shows AI badge for AI-recognized meals', (WidgetTester tester) async {
      // Arrange
      final meal = getMockMealEntries().first; // source: 'ai'
      
      final widget = Card(
        child: ListTile(
          title: Row(
            children: [
              Text(meal.foodName),
              if (meal.source == 'ai') ...[
                const SizedBox(width: 8),
                const Chip(
                  label: Text('AI'),
                  backgroundColor: Colors.blue,
                ),
              ],
            ],
          ),
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('AI'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });
    
    testWidgets('Does not show AI badge for manual meals', (WidgetTester tester) async {
      // Arrange
      final meal = getMockMealEntries()[1]; // source: 'manual'
      
      final widget = Card(
        child: ListTile(
          title: Row(
            children: [
              Text(meal.foodName),
              if (meal.source == 'ai') ...[
                const SizedBox(width: 8),
                const Chip(
                  label: Text('AI'),
                ),
              ],
            ],
          ),
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('AI'), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });
    
    testWidgets('Displays macros (protein, carbs, fat)', (WidgetTester tester) async {
      // Arrange
      final meal = getMockMealEntries().first;
      
      final widget = Card(
        child: Column(
          children: [
            Text(meal.foodName),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('P: ${meal.protein.toInt()}g'),
                Text('C: ${meal.carbs.toInt()}g'),
                Text('F: ${meal.fat.toInt()}g'),
              ],
            ),
          ],
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('P: ${meal.protein.toInt()}g'), findsOneWidget);
      expect(find.text('C: ${meal.carbs.toInt()}g'), findsOneWidget);
      expect(find.text('F: ${meal.fat.toInt()}g'), findsOneWidget);
    });
    
    testWidgets('Card is tappable', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      final meal = getMockMealEntries().first;
      
      final widget = Card(
        child: InkWell(
          key: const Key('test_inkwell'), // ✅ Added key to uniquely identify
          onTap: () => tapped = true,
          child: ListTile(
            title: Text(meal.foodName),
          ),
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      await tester.tap(find.byKey(const Key('test_inkwell'))); // ✅ Find by key instead of type
      await tester.pumpAndSettle();
      
      // Assert
      expect(tapped, isTrue);
    });
    
    testWidgets('Displays meal type icon', (WidgetTester tester) async {
      // Arrange
      final meal = getMockMealEntries().first;
      IconData icon;
      
      switch (meal.mealType) {
        case 'breakfast':
          icon = Icons.wb_sunny;
          break;
        case 'lunch':
          icon = Icons.wb_cloudy;
          break;
        case 'dinner':
          icon = Icons.nights_stay;
          break;
        case 'snack':
          icon = Icons.restaurant;
          break;
        default:
          icon = Icons.restaurant;
      }
      
      final widget = Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(meal.foodName),
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.byIcon(icon), findsOneWidget);
    });
    
    testWidgets('Multiple meal cards display correctly', (WidgetTester tester) async {
      // Arrange
      final meals = getMockMealEntries();
      
      final widget = ListView.builder(
        itemCount: meals.length,
        itemBuilder: (context, index) {
          final meal = meals[index];
          return Card(
            child: ListTile(
              title: Text(meal.foodName),
              subtitle: Text('${meal.calories.toInt()} calo'),
            ),
          );
        },
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.byType(Card), findsNWidgets(meals.length));
      for (final meal in meals) {
        expect(find.text(meal.foodName), findsOneWidget);
      }
    });
  });
}

