import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/image_service.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/repositories/user_food_repository.dart';
import '../../providers/meal_provider.dart';
import '../../providers/food_provider.dart';

/// AI Result Screen - Display AI recognition results
/// 
/// Features:
/// - Show captured image
/// - Display food name
/// - Show nutrition info (calories, protein, carbs, fat)
/// - Confidence score
/// - Single button to add to meal (opens Bottom Sheet)
/// 
/// Flow:
/// Camera → AI Processing (mock) → AI Result → Select Meal Type → Add to DB → Home
class AIResultScreen extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> aiResult; // AI recognition result (mock for Day 4)

  const AIResultScreen({
    super.key,
    required this.imageFile,
    required this.aiResult,
  });

  @override
  State<AIResultScreen> createState() => _AIResultScreenState();
}

class _AIResultScreenState extends State<AIResultScreen> {
  bool _isAdding = false;

  /// Show bottom sheet to select meal type
  void _showMealTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMealTypeBottomSheet(),
    );
  }

  /// Build meal type bottom sheet
  Widget _buildMealTypeBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Chọn bữa ăn',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Meal type buttons
            _buildMealTypeButton(
              'Bữa Sáng',
              'breakfast',
              Icons.wb_sunny,
              AppColors.breakfast,
            ),
            const SizedBox(height: 12),
            
            _buildMealTypeButton(
              'Bữa Trưa',
              'lunch',
              Icons.wb_sunny_outlined,
              AppColors.lunch,
            ),
            const SizedBox(height: 12),
            
            _buildMealTypeButton(
              'Bữa Tối',
              'dinner',
              Icons.nightlight,
              AppColors.dinner,
            ),
            const SizedBox(height: 12),
            
            _buildMealTypeButton(
              'Ăn Vặt',
              'snack',
              Icons.fastfood,
              AppColors.snack,
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build meal type button
  Widget _buildMealTypeButton(
    String label,
    String mealType,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context); // Close bottom sheet
          _addToMeal(mealType); // Add to meal
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Add meal to specific meal type
  Future<void> _addToMeal(String mealType) async {
    if (_isAdding) return;

    setState(() => _isAdding = true);

    try {
      // Save image to permanent storage
      final String? savedImagePath = await ImageService.instance.saveImage(widget.imageFile);

      if (savedImagePath == null) {
        throw Exception('Không thể lưu ảnh');
      }

      final now = DateTime.now();
      final mealEntry = {
        'id': const Uuid().v4(),
        'user_id': 'user_1', // TODO: Get from auth
        'food_id': null, // AI-detected food doesn't have food_id from database
        'food_name': widget.aiResult['food_name'] ?? 'Món ăn',
        'meal_type': mealType.toLowerCase(),
        'date': now.toIso8601String().split('T')[0],
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'calories': (widget.aiResult['calories'] ?? 0).toDouble(),
        'protein': (widget.aiResult['protein'] ?? 0).toDouble(),
        'carbs': (widget.aiResult['carbs'] ?? 0).toDouble(),
        'fat': (widget.aiResult['fat'] ?? 0).toDouble(),
        'portion_size': widget.aiResult['portion_size'] ?? '1 phần',
        'portion_multiplier': 1.0,
        'serving_size': 100.0,
        'servings': 1.0,
        'source': 'ai', // Mark as AI-detected
        'image_path': savedImagePath, // ← Save image path
        'confidence': (widget.aiResult['confidence'] ?? 0.0).toDouble(),
        'created_at': now.toIso8601String(),
      };

      // 1. Save as user food (to "Món của tôi") - AI-scanned food can be edited
      final userFoodRepo = UserFoodRepository();
      await userFoodRepo.createFood(
        userId: 'user_1',
        name: widget.aiResult['food_name'] ?? 'Món ăn',
        portionSize: 100.0, // Default 100g
        calories: (widget.aiResult['calories'] ?? 0).toDouble(),
        protein: (widget.aiResult['protein'] ?? 0).toDouble(),
        carbs: (widget.aiResult['carbs'] ?? 0).toDouble(),
        fat: (widget.aiResult['fat'] ?? 0).toDouble(),
        imagePath: savedImagePath,
        source: 'ai_scan', // Mark as AI-scanned
        aiConfidence: (widget.aiResult['confidence'] ?? 0.0).toDouble(),
      );
      
      // 2. Insert meal entry
      await DatabaseHelper.instance.insertMealEntry(mealEntry);

      // 3. Reload all data
      if (mounted) {
        final mealProvider = context.read<MealProvider>();
        final foodProvider = context.read<FoodProvider>();
        
        // Reload today's meals
        await mealProvider.loadMealsForDate(DateTime.now());
        
        // ✨ NEW: Reload recent meals (for "Gần đây" section)
        await mealProvider.loadRecentMeals();
        
        // ✨ NEW: Reload "Món của tôi" to show new AI food
        await foodProvider.loadMyFoods();
      }

      if (!mounted) return;

      // Show success message
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
                  'Đã thêm ${widget.aiResult['food_name']} vào ${_getMealTitle(mealType)}',
                  style: const TextStyle(
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

      // Go back to home
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('❌ Error adding meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  String _getMealTitle(String mealType) {
    switch (mealType.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final foodName = widget.aiResult['food_name'] ?? 'Món ăn';
    final calories = (widget.aiResult['calories'] ?? 0).toDouble();
    final protein = (widget.aiResult['protein'] ?? 0).toDouble();
    final carbs = (widget.aiResult['carbs'] ?? 0).toDouble();
    final fat = (widget.aiResult['fat'] ?? 0).toDouble();
    final confidence = (widget.aiResult['confidence'] ?? 0.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: Text(
          'Kết quả nhận diện',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isAdding
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang thêm món ăn...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Card
                  _buildImageCard(),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Food Name Card
                  _buildFoodNameCard(foodName, confidence),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Nutrition Card
                  _buildNutritionCard(calories, protein, carbs, fat),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Single "Add to Meal" button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showMealTypeSelector,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Thêm vào bữa ăn',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingL),
                ],
              ),
            ),
    );
  }

  /// Build image card
  Widget _buildImageCard() {
    return Card(
      elevation: AppDimensions.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.file(
            widget.imageFile,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// Build food name card
  Widget _buildFoodNameCard(String foodName, double confidence) {
    return Card(
      elevation: AppDimensions.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodName,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: confidence > 0.8
                            ? AppColors.success
                            : confidence > 0.6
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Độ tin cậy: ${(confidence * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build nutrition card
  Widget _buildNutritionCard(
    double calories,
    double protein,
    double carbs,
    double fat,
  ) {
    return Card(
      elevation: AppDimensions.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin dinh dưỡng',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Calories
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department, color: AppColors.secondary, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    '${calories.toStringAsFixed(0)} kcal',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingL),

            // Macros
            Row(
              children: [
                Expanded(
                  child: _buildMacroItem(
                    'Protein',
                    protein,
                    AppColors.macroProtein,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: _buildMacroItem(
                    'Carbs',
                    carbs,
                    AppColors.macroCarbs,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: _buildMacroItem(
                    'Fat',
                    fat,
                    AppColors.macroFat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build macro item
  Widget _buildMacroItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}g',
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

