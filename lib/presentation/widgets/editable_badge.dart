import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Editable Badge Widget
/// 
/// Shows edit icon (✏️) for custom foods that can be edited
/// Only displayed for user-created foods (isEditable = true)
/// 
/// Usage:
/// ```dart
/// if (food.isEditable) {
///   EditableBadge(
///     onTap: () => navigateToEditScreen(food),
///   )
/// }
/// ```
class EditableBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  const EditableBadge({
    super.key,
    this.onTap,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (color ?? AppColors.secondary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.edit_outlined,
          size: size * 0.8,
          color: color ?? AppColors.secondary,
        ),
      ),
    );
  }
}

