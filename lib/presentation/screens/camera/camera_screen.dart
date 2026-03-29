import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/gpt5_service.dart';
import '../../../core/config/env_config.dart';
import '../ai_result/ai_result_screen.dart';

/// Camera Screen - Capture food images
/// 
/// Features:
/// - Real-time camera preview
/// - Take picture
/// - Switch camera (front/back)
/// - Flash control
/// - Pick from gallery
/// 
/// Flow:
/// Camera Screen → Take Picture → Loading → AI Result Screen (with mock data)
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService.instance;
  final GPT5Service _gpt5Service = GPT5Service.instance;
  
  bool _isInitializing = true;
  String? _errorMessage;
  final bool _useRealAI = true; // Toggle between mock and real AI

  // Mock data for testing (matches new GPT-4 Vision format)
  // Format: List of recognized foods (name, quantity, size, estimated_grams)
  final List<Map<String, dynamic>> _mockFoods = [
    {
      'name_vi': 'Phở Bò',
      'name_en': 'Beef Pho',
      'quantity': 1,
      'size': 'Tô lớn',
      'estimated_grams': 500.0,
      'confidence': 0.92,
    },
    {
      'name_vi': 'Cơm Tấm Sườn',
      'name_en': 'Broken Rice with Pork',
      'quantity': 1,
      'size': 'Đĩa vừa',
      'estimated_grams': 350.0,
      'confidence': 0.88,
    },
    {
      'name_vi': 'Bánh Mì Thịt',
      'name_en': 'Vietnamese Sandwich',
      'quantity': 1,
      'size': '1 ổ',
      'estimated_grams': 200.0,
      'confidence': 0.85,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle (pause/resume camera)
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final bool success = await _cameraService.initialize();

    if (!mounted) return;

    setState(() {
      _isInitializing = false;
      if (!success) {
        _errorMessage = 'Không thể khởi động camera. Vui lòng kiểm tra quyền truy cập.';
      }
    });
  }

  /// Take picture and process with AI (GPT-5 or mock)
  Future<void> _takePicture() async {
    try {
      final imageFile = await _cameraService.takePicture();

      if (imageFile == null) {
        _showSnackBar('Không thể chụp ảnh. Vui lòng thử lại.');
        return;
      }

      if (!mounted) return;

      // Show loading with animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Container(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  _useRealAI ? 'Đang nhận diện món ăn...' : 'Đang xử lý...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // ❌ REMOVED: "GPT-5 đang phân tích" subtitle
              ],
            ),
          ),
        ),
      );

      List<Map<String, dynamic>>? recognizedFoods;

      if (_useRealAI && EnvConfig.isApiKeyConfigured) {
        // Use real GPT-4O AI (faster than GPT-5)
        debugPrint('🤖 Using GPT-4O AI recognition');
        recognizedFoods = await _gpt5Service.recognizeFoodWithRetry(imageFile);

        if (recognizedFoods == null || recognizedFoods.isEmpty) {
          // AI failed, fallback to mock
          debugPrint('⚠️ AI failed, using mock data');
          recognizedFoods = [_mockFoods[Random().nextInt(_mockFoods.length)]];
          
          if (mounted) {
            _showSnackBar('AI không phản hồi, sử dụng dữ liệu demo');
          }
        }
      } else {
        // Use mock data (for testing or if API key not configured)
        debugPrint('🎭 Using mock data');
        await Future.delayed(const Duration(seconds: 2));
        recognizedFoods = [_mockFoods[Random().nextInt(_mockFoods.length)]];
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Navigate to AI Result Screen with first recognized food
      // TODO: Handle multiple foods in future version
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AIResultScreen(
            imageFile: imageFile,
            aiResult: recognizedFoods!.first, // Use first food for now
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error taking picture: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading if open
        _showSnackBar('Lỗi: $e');
      }
    }
  }

  /// Pick image from gallery and process with AI (GPT-5 or mock)
  Future<void> _pickFromGallery() async {
    try {
      final imageFile = await _cameraService.pickFromGallery();

      if (imageFile == null) {
        // User cancelled
        return;
      }

      if (!mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Container(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  _useRealAI ? 'Đang nhận diện món ăn...' : 'Đang xử lý...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // ❌ REMOVED: "GPT-5 đang phân tích" subtitle
              ],
            ),
          ),
        ),
      );

      List<Map<String, dynamic>>? recognizedFoods;

      if (_useRealAI && EnvConfig.isApiKeyConfigured) {
        // Use real GPT-4O AI (faster than GPT-5)
        debugPrint('🤖 Using GPT-4O AI recognition');
        recognizedFoods = await _gpt5Service.recognizeFoodWithRetry(imageFile);

        if (recognizedFoods == null || recognizedFoods.isEmpty) {
          // AI failed, fallback to mock
          debugPrint('⚠️ AI failed, using mock data');
          recognizedFoods = [_mockFoods[Random().nextInt(_mockFoods.length)]];
          
          if (mounted) {
            _showSnackBar('AI không phản hồi, sử dụng dữ liệu demo');
          }
        }
      } else {
        // Use mock data
        debugPrint('🎭 Using mock data');
        await Future.delayed(const Duration(seconds: 2));
        recognizedFoods = [_mockFoods[Random().nextInt(_mockFoods.length)]];
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Navigate to AI Result Screen with first recognized food
      // TODO: Handle multiple foods in future version
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AIResultScreen(
            imageFile: imageFile,
            aiResult: recognizedFoods!.first, // Use first food for now
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading if open
        _showSnackBar('Lỗi: $e');
      }
    }
  }

  /// Switch camera (front/back)
  Future<void> _switchCamera() async {
    final success = await _cameraService.switchCamera();
    if (!success && mounted) {
      _showSnackBar('Không thể chuyển camera');
    } else {
      setState(() {}); // Rebuild to show new camera
    }
  }

  /// Toggle flash mode
  Future<void> _toggleFlash() async {
    await _cameraService.toggleFlash();
    setState(() {}); // Rebuild to show new flash icon
  }

  /// Show snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildCameraView(),
    );
  }

  /// Build loading view
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Đang khởi động camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Thử lại'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Quay lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build camera view
  Widget _buildCameraView() {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        Center(
          child: CameraPreview(controller),
        ),

        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopControls(),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomControls(),
        ),
      ],
    );
  }

  /// Build top controls (back, flash)
  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            _buildControlButton(
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),

            // Flash button
            _buildControlButton(
              icon: _getFlashIcon(),
              onPressed: _toggleFlash,
            ),
          ],
        ),
      ),
    );
  }

  /// Build bottom controls (gallery, capture, switch)
  Widget _buildBottomControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery button
            _buildControlButton(
              icon: Icons.photo_library,
              onPressed: _pickFromGallery,
            ),

            // Capture button (large)
            GestureDetector(
              onTap: _takePicture,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Switch camera button
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              onPressed: _cameraService.camerasCount > 1 ? _switchCamera : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Build control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        iconSize: 28,
        onPressed: onPressed,
      ),
    );
  }

  /// Get flash icon based on current mode
  IconData _getFlashIcon() {
    switch (_cameraService.flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }
}

