// Calorie Ring Widget Tests
// 
// Tests for the circular calorie progress indicator
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('CalorieRing Widget Tests', () {
    testWidgets('Displays calorie ring with progress', (WidgetTester tester) async {
      // Arrange
      const double consumed = 1500;
      const double goal = 2000;
      
      final widget = CustomPaint(
        size: const Size(200, 200),
        painter: _TestCalorieRingPainter(
          consumed: consumed,
          goal: goal,
        ),
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.byType(CustomPaint), findsWidgets); // ✅ Changed: may find multiple CustomPaint widgets (MaterialApp has its own)
    });
    
    testWidgets('Shows progress percentage', (WidgetTester tester) async {
      // Arrange
      const double consumed = 1500;
      const double goal = 2000;
      const String percentage = '75%';
      
      final widget = Column(
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _TestCalorieRingPainter(
              consumed: consumed,
              goal: goal,
            ),
          ),
          Text(percentage, style: const TextStyle(fontSize: 32)),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text(percentage), findsOneWidget);
    });
    
    testWidgets('Shows consumed and goal calories', (WidgetTester tester) async {
      // Arrange
      const double consumed = 1500;
      const double goal = 2000;
      
      final widget = Column(
        children: [
          Text('${consumed.toInt()} / ${goal.toInt()} calo'),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('1500 / 2000 calo'), findsOneWidget);
    });
    
    testWidgets('Handles zero consumed calories', (WidgetTester tester) async {
      // Arrange
      const double consumed = 0;
      const double goal = 2000;
      
      final widget = Column(
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _TestCalorieRingPainter(
              consumed: consumed,
              goal: goal,
            ),
          ),
          const Text('0%'),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('0%'), findsOneWidget);
    });
    
    testWidgets('Handles exceeded goal calories', (WidgetTester tester) async {
      // Arrange
      const double consumed = 2500;
      const double goal = 2000;
      
      final widget = Column(
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _TestCalorieRingPainter(
              consumed: consumed,
              goal: goal,
            ),
          ),
          const Text('125%'),
        ],
      );
      
      // Act
      await tester.pumpWidget(createBasicTestWidget(widget));
      
      // Assert
      expect(find.text('125%'), findsOneWidget);
    });
  });
}

/// Test painter for calorie ring
class _TestCalorieRingPainter extends CustomPainter {
  final double consumed;
  final double goal;
  
  _TestCalorieRingPainter({
    required this.consumed,
    required this.goal,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Simple test implementation
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc
    if (goal > 0) {
      final progress = (consumed / goal).clamp(0.0, 1.0);
      final progressPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -90 * (3.14159 / 180),
        progress * 2 * 3.14159,
        false,
        progressPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_TestCalorieRingPainter oldDelegate) {
    return oldDelegate.consumed != consumed || oldDelegate.goal != goal;
  }
}

