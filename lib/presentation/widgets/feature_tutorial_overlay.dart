import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Feature Tutorial Overlay
/// 
/// Displays contextual tooltips to guide new users through app features
/// Uses SharedPreferences to track which tutorials have been shown
/// 
/// Features:
/// - Auto-show on first use
/// - Skip/dismiss functionality
/// - Beautiful tooltip design
/// - Multiple tutorial steps
class FeatureTutorialOverlay {
  static const String _prefixKey = 'tutorial_shown_';
  
  /// Check if tutorial has been shown
  static Future<bool> hasShownTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefixKey$tutorialId') ?? false;
  }
  
  /// Mark tutorial as shown
  static Future<void> markTutorialShown(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefixKey$tutorialId', true);
  }
  
  /// Reset all tutorials (for testing)
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefixKey));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
  
  /// Show tutorial overlay
  /// 
  /// Parameters:
  /// - [context]: BuildContext
  /// - [tutorialId]: Unique identifier for this tutorial
  /// - [targetKey]: GlobalKey of the widget to highlight
  /// - [title]: Tutorial title
  /// - [description]: Tutorial description
  /// - [position]: Position of tooltip (top, bottom, left, right)
  /// - [onNext]: Callback for next button (if multi-step)
  /// - [onComplete]: Callback when tutorial is completed/dismissed
  static Future<void> show({
    required BuildContext context,
    required String tutorialId,
    required GlobalKey targetKey,
    required String title,
    required String description,
    TooltipPosition position = TooltipPosition.bottom,
    VoidCallback? onNext,
    VoidCallback? onComplete,
  }) async {
    // Check if already shown
    final hasShown = await hasShownTutorial(tutorialId);
    if (hasShown) {
      onComplete?.call();
      return;
    }
    
    // Show overlay
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (dialogContext) => _TutorialOverlay(
          targetKey: targetKey,
          title: title,
          description: description,
          position: position,
          onNext: onNext != null
              ? () {
                  Navigator.pop(dialogContext);
                  onNext();
                }
              : null,
          onSkip: () async {
            await markTutorialShown(tutorialId);
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            onComplete?.call();
          },
        ),
      );
      
      // Mark as shown if no next step
      if (onNext == null) {
        await markTutorialShown(tutorialId);
        onComplete?.call();
      }
    }
  }
  
  /// Show multi-step tutorial
  /// 
  /// Displays a sequence of tutorial steps
  static Future<void> showMultiStep({
    required BuildContext context,
    required String tutorialId,
    required List<TutorialStep> steps,
    VoidCallback? onComplete,
  }) async {
    final hasShown = await hasShownTutorial(tutorialId);
    if (hasShown) {
      onComplete?.call();
      return;
    }
    
    int currentStep = 0;
    
    Future<void> showStep() async {
      if (currentStep >= steps.length) {
        await markTutorialShown(tutorialId);
        onComplete?.call();
        return;
      }
      
      final step = steps[currentStep];
      await show(
        context: context,
        tutorialId: '${tutorialId}_step_$currentStep',
        targetKey: step.targetKey,
        title: step.title,
        description: step.description,
        position: step.position,
        onNext: currentStep < steps.length - 1
            ? () {
                currentStep++;
                showStep();
              }
            : null,
        onComplete: () {
          markTutorialShown(tutorialId);
          onComplete?.call();
        },
      );
    }
    
    await showStep();
  }
}

/// Tutorial step data
class TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final TooltipPosition position;
  
  const TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.position = TooltipPosition.bottom,
  });
}

/// Tooltip position
enum TooltipPosition {
  top,
  bottom,
  left,
  right,
}

/// Tutorial overlay widget
class _TutorialOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final TooltipPosition position;
  final VoidCallback? onNext;
  final VoidCallback onSkip;
  
  const _TutorialOverlay({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.position,
    required this.onNext,
    required this.onSkip,
  });
  
  @override
  Widget build(BuildContext context) {
    // Get target widget position
    final RenderBox? renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      // If target not found, just show dialog in center
      return _buildCenteredDialog(context);
    }
    
    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;
    
    return Stack(
      children: [
        // Highlight target (cut-out effect)
        Positioned.fill(
          child: CustomPaint(
            painter: _HighlightPainter(
              targetRect: targetPosition & targetSize,
            ),
          ),
        ),
        
        // Tooltip
        _buildTooltip(context, targetPosition, targetSize),
      ],
    );
  }
  
  /// Build centered dialog (fallback)
  Widget _buildCenteredDialog(BuildContext context) {
    return Center(
      child: _buildTooltipCard(context),
    );
  }
  
  /// Build tooltip at calculated position
  Widget _buildTooltip(BuildContext context, Offset targetPosition, Size targetSize) {
    final screenSize = MediaQuery.of(context).size;
    double? top, bottom, left, right;
    
    switch (position) {
      case TooltipPosition.bottom:
        top = targetPosition.dy + targetSize.height + 16;
        left = (targetPosition.dx + targetSize.width / 2).clamp(
          AppDimensions.marginLarge + 120,
          screenSize.width - AppDimensions.marginLarge - 120,
        ) - 120;
        break;
      case TooltipPosition.top:
        bottom = screenSize.height - targetPosition.dy + 16;
        left = (targetPosition.dx + targetSize.width / 2).clamp(
          AppDimensions.marginLarge + 120,
          screenSize.width - AppDimensions.marginLarge - 120,
        ) - 120;
        break;
      case TooltipPosition.left:
        top = targetPosition.dy + targetSize.height / 2 - 60;
        right = screenSize.width - targetPosition.dx + 16;
        break;
      case TooltipPosition.right:
        top = targetPosition.dy + targetSize.height / 2 - 60;
        left = targetPosition.dx + targetSize.width + 16;
        break;
    }
    
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: _buildTooltipCard(context),
    );
  }
  
  /// Build tooltip card
  Widget _buildTooltipCard(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppDimensions.marginLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(
                  onNext != null ? 'Bỏ qua' : 'Đã hiểu',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (onNext != null) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tiếp theo'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for highlight effect
class _HighlightPainter extends CustomPainter {
  final Rect targetRect;
  
  _HighlightPainter({required this.targetRect});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw dim overlay with cut-out
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        targetRect.inflate(8),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, paint);
    
    // Draw highlight border
    final borderPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        targetRect.inflate(8),
        const Radius.circular(12),
      ),
      borderPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Quick tutorial helper for common scenarios
class QuickTutorial {
  /// Show "First Time Camera" tutorial
  static Future<void> showCameraIntro(
    BuildContext context,
    GlobalKey cameraButtonKey,
  ) async {
    await FeatureTutorialOverlay.show(
      context: context,
      tutorialId: 'first_camera',
      targetKey: cameraButtonKey,
      title: 'Chụp ảnh món ăn',
      description: 'Nhấn đây để chụp ảnh món ăn. AI sẽ tự động nhận diện và tính calories cho bạn!',
      position: TooltipPosition.top,
    );
  }
  
  /// Show "Add Manual Meal" tutorial
  static Future<void> showAddMealIntro(
    BuildContext context,
    GlobalKey addMealButtonKey,
  ) async {
    await FeatureTutorialOverlay.show(
      context: context,
      tutorialId: 'add_manual_meal',
      targetKey: addMealButtonKey,
      title: 'Thêm thủ công',
      description: 'Nếu không muốn chụp ảnh, bạn có thể thêm món ăn thủ công từ danh sách có sẵn.',
      position: TooltipPosition.bottom,
    );
  }
  
  /// Show "Water Tracking" tutorial
  static Future<void> showWaterIntro(
    BuildContext context,
    GlobalKey waterWidgetKey,
  ) async {
    await FeatureTutorialOverlay.show(
      context: context,
      tutorialId: 'water_tracking',
      targetKey: waterWidgetKey,
      title: 'Theo dõi nước uống',
      description: 'Nhấn các nút để ghi lại lượng nước bạn đã uống. Mục tiêu hàng ngày: 2000ml!',
      position: TooltipPosition.bottom,
    );
  }
  
  /// Show complete home screen tutorial (multi-step)
  static Future<void> showHomeScreenTour(
    BuildContext context, {
    required GlobalKey calorieRingKey,
    required GlobalKey mealChecklistKey,
    required GlobalKey waterWidgetKey,
    required GlobalKey cameraButtonKey,
  }) async {
    await FeatureTutorialOverlay.showMultiStep(
      context: context,
      tutorialId: 'home_screen_tour',
      steps: [
        TutorialStep(
          targetKey: calorieRingKey,
          title: 'Vòng tròn Calories',
          description: 'Đây là tổng calories bạn đã ăn hôm nay. Vòng tròn sẽ đầy khi đạt mục tiêu!',
          position: TooltipPosition.bottom,
        ),
        TutorialStep(
          targetKey: mealChecklistKey,
          title: 'Danh sách bữa ăn',
          description: 'Theo dõi các bữa ăn trong ngày: Sáng, Trưa, Tối, Ăn vặt. Nhấn để xem chi tiết!',
          position: TooltipPosition.bottom,
        ),
        TutorialStep(
          targetKey: waterWidgetKey,
          title: 'Nước uống',
          description: 'Đừng quên uống đủ nước! Nhấn để ghi lại lượng nước bạn uống.',
          position: TooltipPosition.bottom,
        ),
        TutorialStep(
          targetKey: cameraButtonKey,
          title: 'Chụp ảnh món ăn',
          description: 'Nhấn nút này để chụp ảnh món ăn. AI sẽ tự động nhận diện và tính calories!',
          position: TooltipPosition.top,
        ),
      ],
    );
  }
}

