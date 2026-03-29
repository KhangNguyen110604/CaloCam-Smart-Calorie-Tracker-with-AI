import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image Cache Manager
/// 
/// Manages cached meal images to improve performance:
/// - Auto-cleanup old images (>30 days)
/// - Memory-efficient image loading
/// - Cache size management
/// 
/// Usage:
/// ```dart
/// await ImageCacheManager.cleanupOldImages();
/// final size = await ImageCacheManager.getCacheSize();
/// ```
class ImageCacheManager {
  static const int _maxCacheAgeDays = 30;
  // Max cache size limit (can be used for future cache size checks)
  // static const int _maxCacheSizeMB = 100;
  
  /// Clean up old cached images
  /// 
  /// Deletes images older than 30 days to free up storage
  static Future<void> cleanupOldImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mealImagesDir = Directory(path.join(directory.path, 'meal_images'));
      
      if (!await mealImagesDir.exists()) {
        return;
      }
      
      final now = DateTime.now();
      int deletedCount = 0;
      
      await for (final entity in mealImagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;
          
          if (age > _maxCacheAgeDays) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
      
      debugPrint('✅ ImageCacheManager: Deleted $deletedCount old images');
    } catch (e) {
      debugPrint('❌ ImageCacheManager: Error cleaning up: $e');
    }
  }
  
  /// Get total cache size in MB
  static Future<double> getCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mealImagesDir = Directory(path.join(directory.path, 'meal_images'));
      
      if (!await mealImagesDir.exists()) {
        return 0.0;
      }
      
      int totalBytes = 0;
      
      await for (final entity in mealImagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalBytes += stat.size;
        }
      }
      
      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('❌ ImageCacheManager: Error calculating size: $e');
      return 0.0;
    }
  }
  
  /// Clear all cached images
  /// 
  /// Use with caution - this deletes all meal images!
  static Future<void> clearAllCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mealImagesDir = Directory(path.join(directory.path, 'meal_images'));
      
      if (await mealImagesDir.exists()) {
        await mealImagesDir.delete(recursive: true);
        debugPrint('✅ ImageCacheManager: Cleared all cache');
      }
    } catch (e) {
      debugPrint('❌ ImageCacheManager: Error clearing cache: $e');
    }
  }
}

