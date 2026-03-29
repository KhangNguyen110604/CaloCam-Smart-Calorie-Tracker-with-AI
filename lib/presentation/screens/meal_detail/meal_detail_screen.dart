import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../../data/models/unified_food_model.dart';
import '../../../data/models/user_food_model.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/unified_food_card.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealType;

  const MealDetailScreen({
    super.key,
    required this.mealType,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load meals when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealProvider>().loadMealsForDate(DateTime.now());
    });
  }

  Color _getMealColor() {
    switch (widget.mealType.toLowerCase()) {
      case 'breakfast':
        return AppColors.breakfast;
      case 'lunch':
        return AppColors.lunch;
      case 'dinner':
        return AppColors.dinner;
      case 'snack':
        return AppColors.snack;
      default:
        return AppColors.primary;
    }
  }

  String _getMealTitle() {
    switch (widget.mealType.toLowerCase()) {
      case 'breakfast':
        return 'Bữa Sáng';
      case 'lunch':
        return 'Bữa Trưa';
      case 'dinner':
        return 'Bữa Tối';
      case 'snack':
        return 'Ăn Vặt';
      default:
        return 'Bữa Ăn';
    }
  }

  IconData _getMealIcon() {
    switch (widget.mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _getMealColor(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(_getMealIcon(), color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              _getMealTitle(),
              style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Show meal info
            },
          ),
        ],
      ),
      body: Consumer<MealProvider>(
        builder: (context, mealProvider, child) {
          final meals = mealProvider.getMealsByType(widget.mealType);
          final totalCalories = meals.fold<double>(
            0,
            (sum, meal) => sum + meal.calories,
          );
          final totalProtein = meals.fold<double>(
            0,
            (sum, meal) => sum + meal.protein,
          );
          final totalCarbs = meals.fold<double>(
            0,
            (sum, meal) => sum + meal.carbs,
          );
          final totalFat = meals.fold<double>(
            0,
            (sum, meal) => sum + meal.fat,
          );

          return Column(
            children: [
              // Summary Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getMealColor(),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingL,
                  AppDimensions.paddingS,
                  AppDimensions.paddingL,
                  AppDimensions.paddingL,
                ),
                child: Column(
                  children: [
                    // Total Calories
                    Text(
                      totalCalories.toStringAsFixed(0),
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    // Macros Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMacroChip(
                          'Protein',
                          totalProtein,
                          Colors.pink.shade100,
                        ),
                        _buildMacroChip(
                          'Carbs',
                          totalCarbs,
                          Colors.blue.shade100,
                        ),
                        _buildMacroChip(
                          'Fat',
                          totalFat,
                          Colors.orange.shade100,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingM),

              // Meal Items List
              Expanded(
                child: meals.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingM,
                        ),
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          return _buildMealItemCard(meal, mealProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'meal_detail_fab_${widget.mealType}', // ✅ Unique hero tag per meal type
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/add-meal',
            arguments: widget.mealType,
          );
          if (!mounted) return;
          if (result == true) {
            // Reload meals after adding
            if (context.mounted) {
              context.read<MealProvider>().loadMealsForDate(DateTime.now());
            }
          }
        },
        backgroundColor: _getMealColor(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Thêm Món',
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(1),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getMealIcon(),
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Chưa có món ăn nào',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            'Nhấn nút "Thêm Món" để bắt đầu',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItemCard(MealEntryModel meal, MealProvider provider) {
    // Convert MealEntryModel to UnifiedFoodModel for consistent UI
    final unifiedFood = _convertMealToUnifiedFood(meal);
    
    return UnifiedFoodCard(
      food: unifiedFood,
      showFavoriteButton: false, // Don't show star on already-added meals
      showSourceChip: false,     // Don't show source chip
      accentColor: _getMealColor(), // Use meal color for consistency
      onTap: () => _showMealOptions(meal, provider),
    );
  }

  /// Convert MealEntryModel to UnifiedFoodModel for display
  UnifiedFoodModel _convertMealToUnifiedFood(MealEntryModel meal) {
    // Create a temporary UserFoodModel to wrap the meal data
    final tempFood = UserFoodModel(
      id: meal.id ?? '',
      userId: 'user_1',
      name: meal.foodName,
      portionSize: meal.servingSize,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      imagePath: meal.imagePath,
      source: 'manual',
      isEditable: false, // Already added meals are not editable via food list
      createdAt: meal.date,
      usageCount: 0,
    );
    
    return UnifiedFoodModel.fromCustom(
      tempFood,
      isFavorite: false, // Don't show as favorite in meal list
    );
  }

  // ==================== OLD CODE REMOVED ====================
  // _buildFoodImage() and _buildMacroTag() removed - now using UnifiedFoodCard

  void _showMealOptions(MealEntryModel meal, MealProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            // Meal name
            Text(
              meal.foodName,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            // Options
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _showEditPortionDialog(meal, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Xóa'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showDeleteConfirmation();
                if (!mounted) return;
                if (confirm == true) {
                  await provider.deleteMealEntry(meal.id!);
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa món ăn'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa món ăn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showEditPortionDialog(MealEntryModel meal, MealProvider provider) {
    double currentPortion = meal.portionMultiplier;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate nutrition based on current portion
          final baseCalories = meal.calories / meal.portionMultiplier;
          final baseProtein = meal.protein / meal.portionMultiplier;
          final baseCarbs = meal.carbs / meal.portionMultiplier;
          final baseFat = meal.fat / meal.portionMultiplier;
          
          final currentCalories = baseCalories * currentPortion;
          final currentProtein = baseProtein * currentPortion;
          final currentCarbs = baseCarbs * currentPortion;
          final currentFat = baseFat * currentPortion;
          
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusL),
              ),
            ),
            padding: EdgeInsets.only(
              left: AppDimensions.paddingL,
              right: AppDimensions.paddingL,
              top: AppDimensions.paddingL,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.paddingL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                
                // Title
                Text(
                  'Chỉnh sửa khẩu phần',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  meal.foodName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                
                // Portion selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (currentPortion > 0.5) {
                          setState(() => currentPortion -= 0.5);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 40,
                      color: _getMealColor(),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${currentPortion.toStringAsFixed(1)}x',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: _getMealColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (currentPortion < 10) {
                          setState(() => currentPortion += 0.5);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 40,
                      color: _getMealColor(),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.paddingL),
                
                // Nutrition preview
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: _getMealColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${currentCalories.toStringAsFixed(0)} kcal',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: _getMealColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientPreview('Protein', currentProtein, AppColors.macroProtein),
                          _buildNutrientPreview('Carbs', currentCarbs, AppColors.macroCarbs),
                          _buildNutrientPreview('Fat', currentFat, AppColors.macroFat),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppDimensions.paddingL),
                
                // Quick portion buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickPortionButton(
                        'Nhỏ',
                        0.5,
                        currentPortion,
                        (value) => setState(() => currentPortion = value),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: _buildQuickPortionButton(
                        'Vừa',
                        1.0,
                        currentPortion,
                        (value) => setState(() => currentPortion = value),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: _buildQuickPortionButton(
                        'Lớn',
                        1.5,
                        currentPortion,
                        (value) => setState(() => currentPortion = value),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.paddingL),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Update meal entry
                      final updatedMeal = meal.copyWith(
                        portionMultiplier: currentPortion,
                        calories: baseCalories * currentPortion,
                        protein: baseProtein * currentPortion,
                        carbs: baseCarbs * currentPortion,
                        fat: baseFat * currentPortion,
                      );
                      
                      try {
                        await provider.updateMealEntry(updatedMeal);
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Đã cập nhật ${meal.foodName}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              elevation: 6,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getMealColor(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: Text(
                      'Lưu thay đổi',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutrientPreview(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}g',
          style: AppTextStyles.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPortionButton(
    String label,
    double value,
    double currentValue,
    Function(double) onTap,
  ) {
    final isSelected = currentValue == value;
    final color = isSelected ? _getMealColor() : AppColors.border;
    final bgColor = isSelected ? _getMealColor() : Colors.white;
    final textColor = isSelected ? Colors.white : AppColors.textPrimary;
    
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

