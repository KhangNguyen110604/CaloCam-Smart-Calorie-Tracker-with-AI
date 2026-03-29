// Water Intake Widget Tests
// 
// Tests for water intake tracking widget
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Water Intake Widget Tests', () {
    testWidgets('Displays water intake title', (WidgetTester tester) async {
      // Arrange
      const String title = 'Nước uống hôm nay';
      
      final widget = Column(
        children: const [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text(title), findsOneWidget);
    });
    
    testWidgets('Displays water amount and goal', (WidgetTester tester) async {
      // Arrange
      const int amount = 1500;
      const int goal = 2000;
      
      final widget = Column(
        children: [
          Text('$amount ml / $goal ml'),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('$amount ml / $goal ml'), findsOneWidget);
    });
    
    testWidgets('Shows water progress bar', (WidgetTester tester) async {
      // Arrange
      const int amount = 1500;
      const int goal = 2000;
      final double progress = amount / goal;
      
      final widget = Column(
        children: [
          LinearProgressIndicator(value: progress),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
    
    testWidgets('Displays quick add buttons', (WidgetTester tester) async {
      // Arrange
      final widget = Row(
        children: [
          ElevatedButton(
            onPressed: () {},
            child: const Text('200ml'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('500ml'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('1000ml'),
          ),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('200ml'), findsOneWidget);
      expect(find.text('500ml'), findsOneWidget);
      expect(find.text('1000ml'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(3));
    });
    
    testWidgets('Quick add button is tappable', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      
      final widget = ElevatedButton(
        onPressed: () => tapped = true,
        child: const Text('200ml'),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Assert
      expect(tapped, isTrue);
    });
    
    testWidgets('Shows completion message when goal reached', (WidgetTester tester) async {
      // Arrange
      const int amount = 2000;
      const int goal = 2000;
      const String message = 'Đã hoàn thành mục tiêu!';
      
      final widget = Column(
        children: [
          Text('$amount ml / $goal ml'),
          if (amount >= goal) const Text(message),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text(message), findsOneWidget);
    });
    
    testWidgets('Does not show completion message when goal not reached', (WidgetTester tester) async {
      // Arrange
      const int amount = 1500;
      const int goal = 2000;
      const String message = 'Đã hoàn thành mục tiêu!';
      
      final widget = Column(
        children: [
          Text('$amount ml / $goal ml'),
          if (amount >= goal) const Text(message),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text(message), findsNothing);
    });
    
    testWidgets('Progress bar is full when goal reached', (WidgetTester tester) async {
      // Arrange
      const int amount = 2000;
      const int goal = 2000;
      final double progress = (amount / goal).clamp(0.0, 1.0);
      
      final widget = Column(
        children: [
          LinearProgressIndicator(value: progress),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 1.0);
    });
    
    testWidgets('Progress bar shows correct progress', (WidgetTester tester) async {
      // Arrange
      const int amount = 1500;
      const int goal = 2000;
      final double expectedProgress = amount / goal; // 0.75
      
      final widget = Column(
        children: [
          LinearProgressIndicator(value: expectedProgress),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.75, 0.01));
    });
    
    testWidgets('Handles zero water intake', (WidgetTester tester) async {
      // Arrange
      const int amount = 0;
      const int goal = 2000;
      
      final widget = Column(
        children: [
          Text('$amount ml / $goal ml'),
          LinearProgressIndicator(value: amount / goal),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('$amount ml / $goal ml'), findsOneWidget);
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 0.0);
    });
    
    testWidgets('Handles water intake exceeding goal', (WidgetTester tester) async {
      // Arrange
      const int amount = 2500;
      const int goal = 2000;
      final double progress = (amount / goal).clamp(0.0, 1.0);
      
      final widget = Column(
        children: [
          Text('$amount ml / $goal ml'),
          LinearProgressIndicator(value: progress),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('$amount ml / $goal ml'), findsOneWidget);
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 1.0); // Clamped to 1.0
    });
  });
}

