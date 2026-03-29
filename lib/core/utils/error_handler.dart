import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Global Error Handler
/// 
/// Provides consistent error handling and user feedback across the app
/// 
/// Features:
/// - User-friendly error messages
/// - Automatic retry suggestions
/// - Network error detection
/// - Graceful degradation
class ErrorHandler {
  /// Show error snackbar with user-friendly message
  /// 
  /// Automatically translates technical errors to Vietnamese
  static void showError(BuildContext context, dynamic error, {String? customMessage}) {
    String message = customMessage ?? _getErrorMessage(error);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Đóng',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
    
    // Log error for debugging
    debugPrint('❌ Error: $error');
  }
  
  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// Show warning message
  static void showWarning(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
    }
    
    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'Kết nối bị gián đoạn. Vui lòng thử lại.';
    }
    
    // Database errors
    if (errorString.contains('database') || errorString.contains('sql')) {
      return 'Lỗi lưu trữ dữ liệu. Vui lòng khởi động lại ứng dụng.';
    }
    
    // Permission errors
    if (errorString.contains('permission')) {
      return 'Ứng dụng cần quyền truy cập. Vui lòng cấp quyền trong cài đặt.';
    }
    
    // File errors
    if (errorString.contains('file') || errorString.contains('path')) {
      return 'Không thể truy cập tệp. Vui lòng thử lại.';
    }
    
    // Camera errors
    if (errorString.contains('camera')) {
      return 'Không thể mở camera. Vui lòng kiểm tra quyền truy cập.';
    }
    
    // API errors
    if (errorString.contains('api') || errorString.contains('http')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng thử lại sau.';
    }
    
    // Format errors
    if (errorString.contains('format')) {
      return 'Dữ liệu không hợp lệ. Vui lòng thử lại.';
    }
    
    // Default error message
    return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
  }
  
  /// Show retry dialog
  static Future<bool> showRetryDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}

/// Network Status Helper
class NetworkStatus {
  /// Check if device has internet connection
  /// 
  /// Note: This is a simple check. For production, consider using
  /// connectivity_plus package for more accurate detection
  static Future<bool> isConnected() async {
    try {
      // Simple DNS lookup to check connectivity
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

