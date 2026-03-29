import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Camera Service - Singleton
/// 
/// Manages camera lifecycle and operations:
/// - Initialize/dispose camera
/// - Take pictures
/// - Switch between front/back camera
/// - Flash control
/// - Pick from gallery
/// 
/// Usage:
/// ```dart
/// final service = CameraService.instance;
/// await service.initialize();
/// final image = await service.takePicture();
/// service.dispose();
/// ```
class CameraService {
  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  static CameraService get instance => _instance;
  CameraService._internal();

  // Camera state
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.auto;

  // Image picker for gallery
  final ImagePicker _picker = ImagePicker();

  /// Get current camera controller
  CameraController? get controller => _controller;

  /// Check if camera is initialized
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Get current flash mode
  FlashMode get flashMode => _currentFlashMode;

  /// Get available cameras count
  int get camerasCount => _cameras?.length ?? 0;

  /// Initialize camera
  /// 
  /// Returns true if successful, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// final success = await CameraService.instance.initialize();
  /// if (!success) {
  ///   // Handle error
  /// }
  /// ```
  Future<bool> initialize() async {
    try {
      debugPrint('📸 CameraService: Initializing...');

      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('❌ CameraService: No cameras available');
        return false;
      }

      debugPrint('📸 CameraService: Found ${_cameras!.length} camera(s)');

      // Use back camera by default (index 0 is usually back camera)
      return await _initializeCamera(_currentCameraIndex);
    } catch (e) {
      debugPrint('❌ CameraService: Initialize error: $e');
      return false;
    }
  }

  /// Initialize specific camera by index
  Future<bool> _initializeCamera(int cameraIndex) async {
    try {
      // Dispose previous controller if exists
      await _controller?.dispose();

      // Create new controller
      _controller = CameraController(
        _cameras![cameraIndex],
        ResolutionPreset.high, // High quality for AI recognition
        enableAudio: false, // No audio for food photos
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize controller
      await _controller!.initialize();

      // Set flash mode
      await _controller!.setFlashMode(_currentFlashMode);

      _currentCameraIndex = cameraIndex;
      
      debugPrint('✅ CameraService: Camera $_currentCameraIndex initialized');
      return true;
    } catch (e) {
      debugPrint('❌ CameraService: Camera init error: $e');
      return false;
    }
  }

  /// Switch between front and back camera
  /// 
  /// Returns true if successful, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// final switched = await CameraService.instance.switchCamera();
  /// if (switched) {
  ///   setState(() {}); // Rebuild UI
  /// }
  /// ```
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      debugPrint('⚠️ CameraService: Cannot switch, only 1 camera available');
      return false;
    }

    try {
      // Toggle camera index
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
      
      debugPrint('📸 CameraService: Switching to camera $_currentCameraIndex');
      
      return await _initializeCamera(_currentCameraIndex);
    } catch (e) {
      debugPrint('❌ CameraService: Switch camera error: $e');
      return false;
    }
  }

  /// Toggle flash mode (auto → on → off → auto)
  /// 
  /// Returns the new flash mode
  /// 
  /// Example:
  /// ```dart
  /// final newMode = await CameraService.instance.toggleFlash();
  /// print('Flash mode: $newMode');
  /// ```
  Future<FlashMode> toggleFlash() async {
    if (_controller == null || !isInitialized) {
      debugPrint('⚠️ CameraService: Camera not initialized');
      return _currentFlashMode;
    }

    try {
      // Cycle through flash modes: auto → on → off → auto
      switch (_currentFlashMode) {
        case FlashMode.auto:
          _currentFlashMode = FlashMode.always;
          break;
        case FlashMode.always:
          _currentFlashMode = FlashMode.off;
          break;
        case FlashMode.off:
          _currentFlashMode = FlashMode.auto;
          break;
        default:
          _currentFlashMode = FlashMode.auto;
      }

      await _controller!.setFlashMode(_currentFlashMode);
      
      debugPrint('💡 CameraService: Flash mode: $_currentFlashMode');
      
      return _currentFlashMode;
    } catch (e) {
      debugPrint('❌ CameraService: Toggle flash error: $e');
      return _currentFlashMode;
    }
  }

  /// Take a picture
  /// 
  /// Returns File if successful, null otherwise
  /// 
  /// Note: This returns a temporary file. You should move it to permanent
  /// storage using ImageService.
  /// 
  /// Example:
  /// ```dart
  /// final image = await CameraService.instance.takePicture();
  /// if (image != null) {
  ///   // Process image
  /// }
  /// ```
  Future<File?> takePicture() async {
    if (_controller == null || !isInitialized) {
      debugPrint('⚠️ CameraService: Camera not initialized');
      return null;
    }

    try {
      debugPrint('📸 CameraService: Taking picture...');

      // Take picture
      final XFile xFile = await _controller!.takePicture();
      
      debugPrint('✅ CameraService: Picture saved to: ${xFile.path}');
      
      return File(xFile.path);
    } catch (e) {
      debugPrint('❌ CameraService: Take picture error: $e');
      return null;
    }
  }

  /// Pick image from gallery
  /// 
  /// Returns File if user selected an image, null if cancelled
  /// 
  /// Example:
  /// ```dart
  /// final image = await CameraService.instance.pickFromGallery();
  /// if (image != null) {
  ///   // Process image
  /// }
  /// ```
  Future<File?> pickFromGallery() async {
    try {
      debugPrint('🖼️ CameraService: Opening gallery...');

      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Limit size for performance
        maxHeight: 1920,
        imageQuality: 85, // Good quality, reasonable size
      );

      if (xFile == null) {
        debugPrint('ℹ️ CameraService: User cancelled gallery picker');
        return null;
      }

      debugPrint('✅ CameraService: Image selected: ${xFile.path}');
      
      return File(xFile.path);
    } catch (e) {
      debugPrint('❌ CameraService: Pick from gallery error: $e');
      return null;
    }
  }

  /// Dispose camera controller
  /// 
  /// Call this when done using camera (e.g., in dispose() method)
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   CameraService.instance.dispose();
  ///   super.dispose();
  /// }
  /// ```
  Future<void> dispose() async {
    try {
      debugPrint('🔄 CameraService: Disposing...');
      await _controller?.dispose();
      _controller = null;
      debugPrint('✅ CameraService: Disposed');
    } catch (e) {
      debugPrint('❌ CameraService: Dispose error: $e');
    }
  }

  /// Reset service (for testing or error recovery)
  Future<void> reset() async {
    await dispose();
    _cameras = null;
    _currentCameraIndex = 0;
    _currentFlashMode = FlashMode.auto;
    debugPrint('🔄 CameraService: Reset complete');
  }
}

