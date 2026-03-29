import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/unified_food_model.dart';
import 'favorite_badge.dart';
import 'editable_badge.dart';
import 'food_source_chip.dart';

/// Unified Food Card
/// 
/// Displays a food item with:
/// - Food name & image
/// - Calories & macros
/// - Favorite badge (⭐)
/// - Editable badge (✏️) for custom foods
/// - Source chip (Thư viện / Của tôi / Từ AI)
/// 
/// Usage:
/// ```dart
/// UnifiedFoodCard(
///   food: unifiedFoodModel,
///   onTap: () => addToMeal(food),
///   onFavoriteToggle: () => toggleFavorite(food),
///   onEdit: food.isEditable ? () => editFood(food) : null,
/// )
/// ```
class UnifiedFoodCard extends StatelessWidget {
  final UnifiedFoodModel food;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onEdit;
  final bool showFavoriteButton;
  final bool showEditButton;
  final bool showSourceChip;
  final Color? accentColor; // NEW: Meal-specific color (Tối=cam, Vặt=tím, etc.)

  const UnifiedFoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.onFavoriteToggle,
    this.onEdit,
    this.showFavoriteButton = true,
    this.showEditButton = true,
    this.showSourceChip = true,
    this.accentColor, // NEW: Pass meal color for consistency
  });

  @override
  Widget build(BuildContext context) {
    // Use meal-specific color for border when favorited
    final borderColor = food.isFavorite 
        ? (accentColor ?? AppColors.primary).withValues(alpha: 0.5)
        : Colors.transparent;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.marginMedium,
        vertical: AppDimensions.marginSmall,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        side: BorderSide(
          color: borderColor, // Use meal color for border
          width: food.isFavorite ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              // Food image or icon
              _buildFoodImage(),
              
              const SizedBox(width: AppDimensions.marginMedium),
              
              // Food details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.name,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Badges row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Favorite badge
                            if (showFavoriteButton)
                              FavoriteBadge(
                                isFavorite: food.isFavorite,
                                onTap: onFavoriteToggle,
                                size: 24,
                                activeColor: accentColor, // Use meal color when favorited
                              ),
                            
                            // Edit badge (only for custom foods)
                            if (showEditButton && food.isEditable && onEdit != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: EditableBadge(
                                  onTap: onEdit,
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Calories
                    Text(
                      food.calorieString,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Macros
                    Text(
                      food.macroString,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Source chip & usage count
                    Row(
                      children: [
                        if (showSourceChip)
                          FoodSourceChip(
                            source: food.source,
                            isEditable: food.isEditable,
                          ),
                        
                        if (food.usageCount > 0) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.history,
                            size: 12,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${food.usageCount} lần',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build food image or placeholder icon
  Widget _buildFoodImage() {
    if (food.imagePath != null && food.imagePath!.isNotEmpty) {
      // Check if it's a URL (http/https) or local file path
      final isUrl = food.imagePath!.startsWith('http://') || 
                    food.imagePath!.startsWith('https://');
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: isUrl
            ? Image.network(
                food.imagePath!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderIcon();
                },
              )
            : Image.file(
                File(food.imagePath!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderIcon();
                },
              ),
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  /// Build placeholder icon when no image
  Widget _buildPlaceholderIcon() {
    final iconColor = accentColor ?? AppColors.primary; // Use meal color if provided
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Icon(
        _getFoodIcon(),
        size: 32,
        color: iconColor,
      ),
    );
  }

  /// Get appropriate icon based on food source
  /// 
  /// Uses consistent icon across all food types for visual harmony
  IconData _getFoodIcon() {
    if (food.isFromAI) {
      return Icons.auto_awesome; // AI magic ✨
    } else {
      return Icons.restaurant; // 🍴 Unified icon for all food types
    }
  }
}

