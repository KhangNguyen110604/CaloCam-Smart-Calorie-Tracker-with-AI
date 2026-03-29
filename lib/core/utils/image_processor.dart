import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

/// Image Processor Utility
class ImageProcessor {
  ImageProcessor._();

  /// Compress image to reduce file size
  static Future<File> compressImage(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      img.Image resized = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        resized = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
        );
      }

      // Compress
      final compressed = img.encodeJpg(resized, quality: quality);

      // Save to temporary file
      final tempDir = imageFile.parent;
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);

      return tempFile;
    } catch (e) {
      // If compression fails, return original file
      return imageFile;
    }
  }

  /// Convert image to base64 string
  static Future<String> toBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  /// Convert base64 string to image file
  static Future<File> fromBase64(String base64String, String filePath) async {
    try {
      final bytes = base64Decode(base64String);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw Exception('Failed to convert base64 to image: $e');
    }
  }

  /// Get image size in bytes
  static Future<int> getImageSize(File imageFile) async {
    try {
      return await imageFile.length();
    } catch (e) {
      return 0;
    }
  }

  /// Get image dimensions
  static Future<Map<String, int>> getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return {'width': 0, 'height': 0};
      }

      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      return {'width': 0, 'height': 0};
    }
  }

  /// Resize image to specific dimensions
  static Future<File> resizeImage(
    File imageFile, {
    required int width,
    required int height,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final resized = img.copyResize(
        image,
        width: width,
        height: height,
      );

      final compressed = img.encodeJpg(resized, quality: 90);

      final tempDir = imageFile.parent;
      final tempFile = File('${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);

      return tempFile;
    } catch (e) {
      return imageFile;
    }
  }

  /// Crop image to square
  static Future<File> cropToSquare(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final size = image.width < image.height ? image.width : image.height;
      final x = (image.width - size) ~/ 2;
      final y = (image.height - size) ~/ 2;

      final cropped = img.copyCrop(
        image,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      final compressed = img.encodeJpg(cropped, quality: 90);

      final tempDir = imageFile.parent;
      final tempFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);

      return tempFile;
    } catch (e) {
      return imageFile;
    }
  }

  /// Format file size to human readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

