import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Food Source Chip Widget
/// 
/// Displays the source of a food item:
/// - "Thư viện" - Built-in food (green)
/// - "Của tôi" - User's custom food (blue)
/// - "Từ AI" - AI-scanned food (purple)
/// 
/// Usage:
/// ```dart
/// FoodSourceChip(
///   source: 'builtin', // or 'manual' or 'ai_scan'
///   isEditable: true,
/// )
/// ```
class FoodSourceChip extends StatelessWidget {
  final String source; // 'builtin', 'manual', or 'ai_scan'
  final bool isEditable;

  const FoodSourceChip({
    super.key,
    required this.source,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipData = _getChipData();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipData['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipData['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipData['icon'],
            size: 12,
            color: chipData['color'],
          ),
          const SizedBox(width: 4),
          Text(
            chipData['label'],
            style: AppTextStyles.bodySmall.copyWith(
              color: chipData['color'],
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Get chip display data based on source
  Map<String, dynamic> _getChipData() {
    switch (source) {
      case 'builtin':
        return {
          'label': 'Thư viện',
          'color': AppColors.success,
          'icon': Icons.library_books,
        };
      case 'manual':
        return {
          'label': 'Của tôi',
          'color': AppColors.primary,
          'icon': Icons.person,
        };
      case 'ai_scan':
        return {
          'label': 'Từ AI',
          'color': Colors.purple,
          'icon': Icons.auto_awesome,
        };
      default:
        return {
          'label': 'Khác',
          'color': AppColors.textHint,
          'icon': Icons.help_outline,
        };
    }
  }
}

