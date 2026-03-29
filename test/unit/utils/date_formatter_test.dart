// Date Formatter Unit Tests
// 
// Tests for date formatting utilities
// Author: CaloCam Team
// Last updated: 2025-10-21

import 'package:flutter_test/flutter_test.dart';
import 'package:calocount_app/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('Format date only - YYYY-MM-DD', () {
      // Arrange
      final date = DateTime(2025, 10, 21, 14, 30);
      
      // Act
      final formatted = DateFormatter.formatDateOnly(date);
      
      // Assert
      expect(formatted, '2025-10-21');
    });
    
    test('Format time only - HH:mm', () {
      // Arrange
      final date = DateTime(2025, 10, 21, 14, 30);
      
      // Act
      final formatted = DateFormatter.formatTime(date); // ✅ Use formatTime instead
      
      // Assert
      expect(formatted, '14:30');
    });
    
    test('Format time only - Single digit hour/minute', () {
      // Arrange
      final date = DateTime(2025, 10, 21, 9, 5);
      
      // Act
      final formatted = DateFormatter.formatTime(date); // ✅ Use formatTime instead
      
      // Assert
      expect(formatted, '09:05'); // Should pad with zeros
    });
    
    test('Format date with weekday - Vietnamese', () {
      // Arrange
      final date = DateTime(2025, 10, 21); // Tuesday
      
      // Act
      final formatted = DateFormatter.formatDateWithWeekday(date);
      
      // Assert
      expect(formatted, contains('Thứ'));
      expect(formatted, contains('21/10/2025'));
    });
    
    test('Format relative date - Today', () {
      // Arrange
      final now = DateTime.now();
      
      // Act
      final formatted = DateFormatter.formatRelativeDate(now);
      
      // Assert
      expect(formatted, 'Hôm nay');
    });
    
    test('Format relative date - Yesterday', () {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      // Act
      final formatted = DateFormatter.formatRelativeDate(yesterday);
      
      // Assert
      expect(formatted, 'Hôm qua');
    });
    
    test('Format relative date - 2 days ago', () {
      // Arrange
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      
      // Act
      final formatted = DateFormatter.formatRelativeDate(twoDaysAgo);
      
      // Assert
      // Should return "2 ngày trước" (within 7 days)
      expect(formatted, isNot('Hôm nay'));
      expect(formatted, isNot('Hôm qua'));
      expect(formatted, '2 ngày trước'); // ✅ Fixed: formatRelativeDate shows "X ngày trước" for 2-7 days
    });
    
    test('Format relative date - More than a week ago', () {
      // Arrange
      final weekAgo = DateTime.now().subtract(const Duration(days: 10));
      
      // Act
      final formatted = DateFormatter.formatRelativeDate(weekAgo);
      
      // Assert
      expect(formatted, contains('/'));
      expect(formatted.split('/').length, 3); // ✅ Fixed: formatShortDate returns DD/MM/YYYY (3 parts)
    });
    
    test('Get start of day', () {
      // Arrange
      final date = DateTime(2025, 10, 21, 14, 30, 45);
      
      // Act
      final startOfDay = DateFormatter.startOfDay(date);
      
      // Assert
      expect(startOfDay.year, 2025);
      expect(startOfDay.month, 10);
      expect(startOfDay.day, 21);
      expect(startOfDay.hour, 0);
      expect(startOfDay.minute, 0);
      expect(startOfDay.second, 0);
      expect(startOfDay.millisecond, 0);
    });
    
    test('Get end of day', () {
      // Arrange
      final date = DateTime(2025, 10, 21, 14, 30, 45);
      
      // Act
      final endOfDay = DateFormatter.endOfDay(date);
      
      // Assert
      expect(endOfDay.year, 2025);
      expect(endOfDay.month, 10);
      expect(endOfDay.day, 21);
      expect(endOfDay.hour, 23);
      expect(endOfDay.minute, 59);
      expect(endOfDay.second, 59);
      expect(endOfDay.millisecond, 999);
    });
    
    test('Get start of week', () {
      // Arrange
      final date = DateTime(2025, 10, 23); // Thursday
      
      // Act
      final startOfWeek = DateFormatter.startOfWeek(date);
      
      // Assert
      // Start of week should be Monday (20th)
      expect(startOfWeek.weekday, DateTime.monday);
      expect(startOfWeek.day, lessThanOrEqualTo(23));
    });
    
    test('Get end of week', () {
      // Arrange
      final date = DateTime(2025, 10, 23); // Thursday
      
      // Act
      final endOfWeek = DateFormatter.endOfWeek(date);
      
      // Assert
      // End of week should be Sunday
      expect(endOfWeek.weekday, DateTime.sunday);
      expect(endOfWeek.day, greaterThanOrEqualTo(23));
    });
    
    test('Get start of month', () {
      // Arrange
      final date = DateTime(2025, 10, 21);
      
      // Act
      final startOfMonth = DateFormatter.startOfMonth(date);
      
      // Assert
      expect(startOfMonth.year, 2025);
      expect(startOfMonth.month, 10);
      expect(startOfMonth.day, 1);
      expect(startOfMonth.hour, 0);
      expect(startOfMonth.minute, 0);
    });
    
    test('Get end of month', () {
      // Arrange
      final date = DateTime(2025, 10, 21);
      
      // Act
      final endOfMonth = DateFormatter.endOfMonth(date);
      
      // Assert
      expect(endOfMonth.year, 2025);
      expect(endOfMonth.month, 10);
      expect(endOfMonth.day, 31); // October has 31 days
      expect(endOfMonth.hour, 23);
      expect(endOfMonth.minute, 59);
    });
    
    test('Get end of month - February (non-leap year)', () {
      // Arrange
      final date = DateTime(2023, 2, 15);
      
      // Act
      final endOfMonth = DateFormatter.endOfMonth(date);
      
      // Assert
      expect(endOfMonth.day, 28);
    });
    
    test('Get end of month - February (leap year)', () {
      // Arrange
      final date = DateTime(2024, 2, 15);
      
      // Act
      final endOfMonth = DateFormatter.endOfMonth(date);
      
      // Assert
      expect(endOfMonth.day, 29);
    });
    
    // ✅ Removed tests for non-existent methods (daysBetween, isSameDay)
  });
}

