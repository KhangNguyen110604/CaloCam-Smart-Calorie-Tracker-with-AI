import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Favorite Badge Widget
/// 
/// Animated star icon for toggling favorite status
/// Shows filled star (⭐) when favorited, outline star (☆) when not
/// 
/// Features:
/// - Smooth scale animation on tap
/// - Color animation
/// - Haptic feedback
/// 
/// Usage:
/// ```dart
/// FavoriteBadge(
///   isFavorite: true,
///   onTap: () => toggleFavorite(),
/// )
/// ```
class FavoriteBadge extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteBadge({
    super.key,
    required this.isFavorite,
    this.onTap,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<FavoriteBadge> createState() => _FavoriteBadgeState();
}

class _FavoriteBadgeState extends State<FavoriteBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoriteBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      // Animate on favorite status change
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.isFavorite ? Icons.star : Icons.star_border, // ⭐ star instead of heart
          size: widget.size,
          color: widget.isFavorite
              ? (widget.activeColor ?? AppColors.accent) // Yellow/orange for favorited
              : (widget.inactiveColor ?? AppColors.textHint),
        ),
      ),
    );
  }
}

