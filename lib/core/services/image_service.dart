import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

/// Image Service - Singleton
/// 
/// Manages image storage and operations:
/// - Save images to permanent storage
/// - Generate unique filenames
/// - Get storage directory
/// - Delete images
/// - Clean up orphaned images
/// 
/// Storage structure:
/// ```
/// app_directory/
///   └── meal_images/
///       ├── image_uuid1.jpg
///       ├── image_uuid2.jpg
///       └── ...
/// ```
/// 
/// Usage:
/// ```dart
/// final service = ImageService.instance;
/// final savedPath = await service.saveImage(tempFile);
/// ```
class ImageService {
  // Singleton pattern
  static final ImageService _instance = ImageService._internal();
  static ImageService get instance => _instance;
  ImageService._internal();

  // Constants
  static const String _imagesFolderName = 'meal_images';
  static const String _thumbnailsFolderName = 'thumbnails';
  
  // Image compression settings
  static const int _maxImageWidth = 800; // Reduced for faster upload
  static const int _maxImageHeight = 800;
  static const int _imageQuality = 85; // 0-100
  
  // Thumbnail settings
  static const int _thumbnailSize = 200;
  static const int _thumbnailQuality = 80;
  
  // UUID generator for unique filenames
  final Uuid _uuid = const Uuid();

  /// Get the directory where meal images are stored
  /// 
  /// Creates the directory if it doesn't exist
  /// 
  /// Returns Directory or null if error
  Future<Directory?> _getImagesDirectory() async {
    try {
      // Get app documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      
      // Create meal_images subdirectory
      final Directory imagesDir = Directory(
        path.join(appDir.path, _imagesFolderName),
      );

      // Create directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        debugPrint('📁 ImageService: Created directory: ${imagesDir.path}');
      }

      return imagesDir;
    } catch (e) {
      debugPrint('❌ ImageService: Get directory error: $e');
      return null;
    }
  }

  /// Compress and resize image
  /// 
  /// Reduces image size while maintaining quality
  /// 
  /// Parameters:
  /// - [imageFile]: Original image file
  /// - [maxWidth]: Maximum width (default: 1024)
  /// - [maxHeight]: Maximum height (default: 1024)
  /// - [quality]: JPEG quality 0-100 (default: 85)
  /// 
  /// Returns compressed image bytes or null if error
  Future<Uint8List?> compressImage(
    File imageFile, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      debugPrint('🗜️ ImageService: Compressing image...');
      
      final int targetWidth = maxWidth ?? _maxImageWidth;
      final int targetHeight = maxHeight ?? _maxImageHeight;
      final int targetQuality = quality ?? _imageQuality;

      // Read image file
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('❌ ImageService: Cannot decode image');
        return null;
      }

      debugPrint('📐 ImageService: Original size: ${originalImage.width}x${originalImage.height}');

      // Calculate new dimensions (maintain aspect ratio)
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > targetWidth || newHeight > targetHeight) {
        final double aspectRatio = newWidth / newHeight;

        if (newWidth > newHeight) {
          newWidth = targetWidth;
          newHeight = (targetWidth / aspectRatio).round();
        } else {
          newHeight = targetHeight;
          newWidth = (targetHeight * aspectRatio).round();
        }
      }

      debugPrint('📐 ImageService: New size: ${newWidth}x$newHeight');

      // Resize image
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with quality
      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: targetQuality),
      );

      final double originalSize = imageBytes.length / 1024 / 1024;
      final double compressedSize = compressedBytes.length / 1024 / 1024;
      final double reduction = ((1 - compressedSize / originalSize) * 100);

      debugPrint('✅ ImageService: Compressed ${originalSize.toStringAsFixed(2)}MB → ${compressedSize.toStringAsFixed(2)}MB (${reduction.toStringAsFixed(1)}% reduction)');

      return compressedBytes;
    } catch (e) {
      debugPrint('❌ ImageService: Compress error: $e');
      return null;
    }
  }

  /// Save image to permanent storage with compression
  /// 
  /// Takes a temporary image file, compresses it, and saves to permanent storage
  /// with a unique filename.
  /// 
  /// Parameters:
  /// - [tempFile]: Temporary image file (from camera or gallery)
  /// - [compress]: Whether to compress image (default: true)
  /// 
  /// Returns:
  /// - String: Full path to saved image
  /// - null: If error occurred
  /// 
  /// Example:
  /// ```dart
  /// final tempImage = await CameraService.instance.takePicture();
  /// final savedPath = await ImageService.instance.saveImage(tempImage);
  /// if (savedPath != null) {
  ///   // Save path to database
  ///   meal.imagePath = savedPath;
  /// }
  /// ```
  Future<String?> saveImage(File tempFile, {bool compress = true}) async {
    try {
      debugPrint('💾 ImageService: Saving image...');

      // Get images directory
      final Directory? imagesDir = await _getImagesDirectory();
      if (imagesDir == null) {
        debugPrint('❌ ImageService: Cannot get images directory');
        return null;
      }

      // Generate unique filename with UUID
      final String uniqueId = _uuid.v4();
      final String filename = '$uniqueId.jpg'; // Always save as JPEG
      final String newPath = path.join(imagesDir.path, filename);

      File savedFile;

      if (compress) {
        // Compress image before saving
        final Uint8List? compressedBytes = await compressImage(tempFile);
        
        if (compressedBytes == null) {
          debugPrint('⚠️ ImageService: Compression failed, saving original');
          savedFile = await tempFile.copy(newPath);
        } else {
          // Write compressed bytes to file
          savedFile = File(newPath);
          await savedFile.writeAsBytes(compressedBytes);
        }
      } else {
        // Save original without compression
        savedFile = await tempFile.copy(newPath);
      }

      debugPrint('✅ ImageService: Image saved to: ${savedFile.path}');
      debugPrint('📊 ImageService: File size: ${(await savedFile.length() / 1024).toStringAsFixed(0)} KB');

      return savedFile.path;
    } catch (e) {
      debugPrint('❌ ImageService: Save image error: $e');
      return null;
    }
  }

  /// Get thumbnails directory
  Future<Directory?> _getThumbnailsDirectory() async {
    try {
      final Directory? imagesDir = await _getImagesDirectory();
      if (imagesDir == null) return null;

      final Directory thumbnailsDir = Directory(
        path.join(imagesDir.path, _thumbnailsFolderName),
      );

      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
        debugPrint('📁 ImageService: Created thumbnails directory');
      }

      return thumbnailsDir;
    } catch (e) {
      debugPrint('❌ ImageService: Get thumbnails directory error: $e');
      return null;
    }
  }

  /// Generate thumbnail for image
  /// 
  /// Creates a small version of the image for faster loading in lists
  /// 
  /// Parameters:
  /// - [imagePath]: Path to original image
  /// - [targetSize]: Thumbnail size (default: 200x200)
  /// 
  /// Returns path to thumbnail or null if error
  Future<String?> generateThumbnail(String imagePath, {int? targetSize}) async {
    try {
      debugPrint('🖼️ ImageService: Generating thumbnail...');

      final int thumbnailSize = targetSize ?? _thumbnailSize;
      final File imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        debugPrint('❌ ImageService: Image file not found');
        return null;
      }

      // Get thumbnails directory
      final Directory? thumbnailsDir = await _getThumbnailsDirectory();
      if (thumbnailsDir == null) return null;

      // Generate thumbnail filename (same UUID as original)
      final String filename = path.basename(imagePath);
      final String thumbnailPath = path.join(thumbnailsDir.path, filename);

      // Check if thumbnail already exists
      if (await File(thumbnailPath).exists()) {
        debugPrint('ℹ️ ImageService: Thumbnail already exists');
        return thumbnailPath;
      }

      // Read and decode image
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('❌ ImageService: Cannot decode image for thumbnail');
        return null;
      }

      // Create square thumbnail (crop to center)
      final int cropSize = originalImage.width < originalImage.height
          ? originalImage.width
          : originalImage.height;

      final img.Image cropped = img.copyCrop(
        originalImage,
        x: (originalImage.width - cropSize) ~/ 2,
        y: (originalImage.height - cropSize) ~/ 2,
        width: cropSize,
        height: cropSize,
      );

      // Resize to thumbnail size
      final img.Image thumbnail = img.copyResize(
        cropped,
        width: thumbnailSize,
        height: thumbnailSize,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG
      final Uint8List thumbnailBytes = Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: _thumbnailQuality),
      );

      // Save thumbnail
      final File thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      debugPrint('✅ ImageService: Thumbnail generated: ${(thumbnailBytes.length / 1024).toStringAsFixed(0)} KB');

      return thumbnailPath;
    } catch (e) {
      debugPrint('❌ ImageService: Generate thumbnail error: $e');
      return null;
    }
  }

  /// Delete image from storage
  /// 
  /// Parameters:
  /// - [imagePath]: Full path to image file
  /// 
  /// Returns:
  /// - true: If deleted successfully
  /// - false: If error occurred or file doesn't exist
  /// 
  /// Example:
  /// ```dart
  /// final deleted = await ImageService.instance.deleteImage(meal.imagePath);
  /// if (deleted) {
  ///   print('Image deleted');
  /// }
  /// ```
  Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      debugPrint('⚠️ ImageService: No image path provided');
      return false;
    }

    try {
      // Delete main image
      final File file = File(imagePath);

      if (!await file.exists()) {
        debugPrint('⚠️ ImageService: File does not exist: $imagePath');
        return false;
      }

      await file.delete();
      debugPrint('🗑️ ImageService: Deleted image: $imagePath');

      // Delete thumbnail if exists
      final Directory? thumbnailsDir = await _getThumbnailsDirectory();
      if (thumbnailsDir != null) {
        final String filename = path.basename(imagePath);
        final String thumbnailPath = path.join(thumbnailsDir.path, filename);
        final File thumbnailFile = File(thumbnailPath);

        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
          debugPrint('🗑️ ImageService: Deleted thumbnail: $thumbnailPath');
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ ImageService: Delete image error: $e');
      return false;
    }
  }

  /// Get all image files in storage
  /// 
  /// Returns list of File objects
  /// 
  /// Example:
  /// ```dart
  /// final images = await ImageService.instance.getAllImages();
  /// print('Total images: ${images.length}');
  /// ```
  Future<List<File>> getAllImages() async {
    try {
      final Directory? imagesDir = await _getImagesDirectory();
      if (imagesDir == null) return [];

      if (!await imagesDir.exists()) return [];

      final List<FileSystemEntity> entities = await imagesDir.list().toList();
      
      // Filter only files (not directories)
      final List<File> imageFiles = entities
          .whereType<File>()
          .where((file) {
            final ext = path.extension(file.path).toLowerCase();
            return ext == '.jpg' || ext == '.jpeg' || ext == '.png';
          })
          .toList();

      debugPrint('📊 ImageService: Found ${imageFiles.length} image(s)');
      
      return imageFiles;
    } catch (e) {
      debugPrint('❌ ImageService: Get all images error: $e');
      return [];
    }
  }

  /// Clean up orphaned images
  /// 
  /// Deletes images that are not referenced in the database.
  /// 
  /// Parameters:
  /// - [usedImagePaths]: List of image paths currently in use (from database)
  /// 
  /// Returns number of deleted images
  /// 
  /// Example:
  /// ```dart
  /// // Get all image paths from database
  /// final usedPaths = await DatabaseHelper.instance.getAllImagePaths();
  /// 
  /// // Clean up orphaned images
  /// final deletedCount = await ImageService.instance.cleanupOrphanedImages(usedPaths);
  /// print('Deleted $deletedCount orphaned image(s)');
  /// ```
  Future<int> cleanupOrphanedImages(List<String> usedImagePaths) async {
    try {
      debugPrint('🧹 ImageService: Cleaning up orphaned images...');

      // Get all images in storage
      final List<File> allImages = await getAllImages();
      
      if (allImages.isEmpty) {
        debugPrint('ℹ️ ImageService: No images to clean up');
        return 0;
      }

      // Convert used paths to Set for faster lookup
      final Set<String> usedPathsSet = usedImagePaths.toSet();

      int deletedCount = 0;

      // Check each image
      for (final File imageFile in allImages) {
        final String imagePath = imageFile.path;

        // If image is not in used paths, delete it
        if (!usedPathsSet.contains(imagePath)) {
          final bool deleted = await deleteImage(imagePath);
          if (deleted) {
            deletedCount++;
            debugPrint('🗑️ ImageService: Deleted orphaned: $imagePath');
          }
        }
      }

      debugPrint('✅ ImageService: Cleanup complete. Deleted $deletedCount image(s)');
      
      return deletedCount;
    } catch (e) {
      debugPrint('❌ ImageService: Cleanup error: $e');
      return 0;
    }
  }

  /// Get total storage size used by images
  /// 
  /// Returns size in bytes
  /// 
  /// Example:
  /// ```dart
  /// final bytes = await ImageService.instance.getTotalStorageSize();
  /// final mb = bytes / (1024 * 1024);
  /// print('Storage used: ${mb.toStringAsFixed(2)} MB');
  /// ```
  Future<int> getTotalStorageSize() async {
    try {
      final List<File> images = await getAllImages();
      
      int totalSize = 0;
      for (final File image in images) {
        totalSize += await image.length();
      }

      final double mb = totalSize / (1024 * 1024);
      debugPrint('📊 ImageService: Total storage: ${mb.toStringAsFixed(2)} MB');
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ ImageService: Get storage size error: $e');
      return 0;
    }
  }

  /// Check if image file exists
  /// 
  /// Parameters:
  /// - [imagePath]: Full path to image file
  /// 
  /// Returns true if file exists, false otherwise
  Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;
    
    try {
      final File file = File(imagePath);
      return await file.exists();
    } catch (e) {
      debugPrint('❌ ImageService: Check exists error: $e');
      return false;
    }
  }

  /// Get image file from path
  /// 
  /// Returns File object or null if doesn't exist
  Future<File?> getImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ImageService: Get image file error: $e');
      return null;
    }
  }
}

