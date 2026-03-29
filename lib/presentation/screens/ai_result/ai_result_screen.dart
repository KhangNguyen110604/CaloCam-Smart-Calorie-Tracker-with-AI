import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/image_service.dart';
import '../../../data/datasources/local/shared_prefs_helper.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../providers/meal_provider.dart';
import '../../providers/food_provider.dart';

/// AI Result Screen - NEW VERSION with Nutrition Lookup
/// 
/// Flow:
/// 1. GPT-4 Vision recognizes food (name, quantity, size, grams)
/// 2. Lookup nutrition from 3 layers:
///    - Local Database (fast, offline)
///    - FatSecret API (online, free)
///    - Manual Input (fallback)
/// 3. Display result with nutrition data
/// 4. Add to meal
/// 
/// Features:
/// - Show captured image
/// - Display recognized food name
/// - Show nutrition info (calories, protein, carbs, fat)
/// - Confidence score
/// - Data source indicator (local/API/manual)
/// - Single button to add to meal (opens Bottom Sheet)
class AIResultScreen extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> aiResult; // AI recognition result (NEW FORMAT)

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
  bool _isLoadingNutrition = true; // Loading nutrition data
  Map<String, dynamic>? _nutritionData; // Nutrition from lookup
  String? _nutritionSource; // 'local', 'api', or 'manual'

  final NutritionRepository _nutritionRepo = NutritionRepository.instance;

  @override
  void initState() {
    super.initState();
    _lookupNutrition(); // Lookup nutrition on init
  }

  /// Lookup nutrition data for recognized food
  /// 
  /// Flow:
  /// 1. Get food name from AI result
  /// 2. Try to find nutrition in database/API (3-layer lookup)
  /// 3. If not found, show manual input dialog
  Future<void> _lookupNutrition() async {
    setState(() => _isLoadingNutrition = true);

    try {
      // Extract food info from AI result
      final foodName = widget.aiResult['name_vi'] ?? widget.aiResult['name_en'] ?? 'Món ăn';
      final estimatedGrams = (widget.aiResult['estimated_grams'] as num?)?.toDouble() ?? 100.0;

      debugPrint('🔍 [AIResult] Looking up nutrition for: $foodName ($estimatedGrams g)');

      // Try to get nutrition from repository (3-layer lookup)
      final nutrition = await _nutritionRepo.getNutrition(
        foodName,
        grams: estimatedGrams,
      );

      if (nutrition != null) {
        // Found! Use the nutrition data
        setState(() {
          _nutritionData = nutrition;
          _nutritionSource = nutrition['source']; // 'local' or 'api'
          _isLoadingNutrition = false;
        });
        
        debugPrint('✅ [AIResult] Nutrition found from ${nutrition['source']}');
      } else {
        // Not found - show manual input dialog
        debugPrint('⚠️ [AIResult] Nutrition not found, asking user...');
        if (mounted) {
          await _showManualNutritionInput(foodName, estimatedGrams);
        }
      }
    } catch (e) {
      debugPrint('❌ [AIResult] Error looking up nutrition: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tra cứu dinh dưỡng: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoadingNutrition = false);
      }
    }
  }

  /// Show manual nutrition input dialog
  /// 
  /// When nutrition data is not found in database/API,
  /// ask user to input manually.
  Future<void> _showManualNutritionInput(String foodName, double grams) async {
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();

    final result = await showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nhập thông tin dinh dưỡng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Không tìm thấy dữ liệu cho "$foodName".\nVui lòng nhập thông tin dinh dưỡng:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Calories
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal) *',
                  hintText: 'VD: 350',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              // Protein
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  hintText: 'VD: 15',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              // Carbs
              TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Carbs (g)',
                  hintText: 'VD: 45',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              // Fat
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fat (g)',
                  hintText: 'VD: 12',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 12),
              Text(
                'Lưu ý: Nhập giá trị cho ${grams.toStringAsFixed(0)}g',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final calories = double.tryParse(caloriesController.text);
              if (calories == null || calories <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập calories hợp lệ')),
                );
                return;
              }
              
              Navigator.pop(context, {
                'calories': calories,
                'protein': double.tryParse(proteinController.text) ?? 0,
                'carbs': double.tryParse(carbsController.text) ?? 0,
                'fat': double.tryParse(fatController.text) ?? 0,
              });
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      // User provided manual input
      // Convert to per 100g and save to database
      final multiplier = 100.0 / grams;
      final caloriesPer100g = result['calories']! * multiplier;
      final proteinPer100g = result['protein']! * multiplier;
      final carbsPer100g = result['carbs']! * multiplier;
      final fatPer100g = result['fat']! * multiplier;

      // Save user contribution
      await _nutritionRepo.saveUserContribution(
        foodName,
        caloriesPer100g,
        protein: proteinPer100g,
        carbs: carbsPer100g,
        fat: fatPer100g,
        foodNameVi: widget.aiResult['name_vi'],
        foodNameEn: widget.aiResult['name_en'],
      );

      // Use the manual input
      setState(() {
        _nutritionData = {
          'food_name': foodName,
          'calories': result['calories']!,
          'protein': result['protein']!,
          'carbs': result['carbs']!,
          'fat': result['fat']!,
          'portion_grams': grams,
          'source': 'manual',
          'data_source': 'user',
        };
        _nutritionSource = 'manual';
        _isLoadingNutrition = false;
      });

      debugPrint('✅ [AIResult] Manual input saved');
    } else {
      // User cancelled - go back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

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
  /// 
  /// ⚠️ CRITICAL: Uses userId from SharedPrefs for data isolation
  Future<void> _addToMeal(String mealType) async {
    if (_isAdding || _nutritionData == null) return;

    setState(() => _isAdding = true);

    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        throw Exception('Không tìm thấy user ID. Vui lòng đăng nhập lại.');
      }

      // Save image to permanent storage
      final String? savedImagePath = await ImageService.instance.saveImage(widget.imageFile);

      if (savedImagePath == null) {
        throw Exception('Không thể lưu ảnh');
      }

      final now = DateTime.now();
      final foodName = widget.aiResult['name_vi'] ?? widget.aiResult['name_en'] ?? 'Món ăn';
      
      final mealEntry = {
        'id': const Uuid().v4(),
        'user_id': userId, // ✅ Dynamic user ID
        'food_id': null, // AI-detected food doesn't have food_id from database
        'food_name': foodName,
        'meal_type': mealType.toLowerCase(),
        'date': now.toIso8601String().split('T')[0],
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'calories': _nutritionData!['calories'],
        'protein': _nutritionData!['protein'],
        'carbs': _nutritionData!['carbs'],
        'fat': _nutritionData!['fat'],
        'portion_size': widget.aiResult['size'] ?? '1 phần',
        'portion_multiplier': 1.0,
        'serving_size': _nutritionData!['portion_grams'],
        'servings': 1.0,
        'source': 'ai', // Mark as AI-detected
        'image_path': savedImagePath,
        'confidence': (widget.aiResult['confidence'] ?? 0.0).toDouble(),
        'created_at': now.toIso8601String(),
      };

      // Get providers
      if (!mounted) return;
      
      final mealProvider = context.read<MealProvider>();
      final foodProvider = context.read<FoodProvider>();
      
      // 1. Save as user food (to "Món của tôi") via FoodProvider (for Firestore sync)
      await foodProvider.createFood(
        name: foodName,
        portionSize: _nutritionData!['portion_grams'],
        calories: _nutritionData!['calories'],
        protein: _nutritionData!['protein'],
        carbs: _nutritionData!['carbs'],
        fat: _nutritionData!['fat'],
        imagePath: savedImagePath,
        source: 'ai_scan', // Mark as AI-scanned
        aiConfidence: (widget.aiResult['confidence'] ?? 0.0).toDouble(),
      );
      
      debugPrint('✅ [AIResult] Saved user food for user $userId: $foodName');
      
      // 2. Add meal entry via MealProvider (for Firestore sync)
      if (mounted) {
        // Convert Map to MealEntryModel
        final meal = MealEntryModel.fromMap(mealEntry);
        
        // Use MealProvider to add meal (this will sync to Firestore)
        await mealProvider.addMealEntry(meal);
        
        debugPrint('✅ [AIResult] Added meal entry for user $userId: $foodName ($mealType)');
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
                  'Đã thêm $foodName vào ${_getMealTitle(mealType)}',
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
    final foodName = widget.aiResult['name_vi'] ?? widget.aiResult['name_en'] ?? 'Món ăn';
    final confidence = (widget.aiResult['confidence'] ?? 0.0).toDouble();
    final estimatedGrams = (widget.aiResult['estimated_grams'] ?? 100.0).toDouble();

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
      body: _isLoadingNutrition
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tra cứu thông tin dinh dưỡng...'),
                ],
              ),
            )
          : _isAdding
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
                      _buildFoodNameCard(foodName, confidence, estimatedGrams),

                      const SizedBox(height: AppDimensions.paddingL),

                      // Nutrition Card
                      if (_nutritionData != null)
                        _buildNutritionCard(
                          _nutritionData!['calories'],
                          _nutritionData!['protein'],
                          _nutritionData!['carbs'],
                          _nutritionData!['fat'],
                        ),

                      const SizedBox(height: AppDimensions.paddingXL),

                      // Single "Add to Meal" button
                      if (_nutritionData != null)
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
  Widget _buildFoodNameCard(String foodName, double confidence, double grams) {
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
                  Text(
                    '${grams.toStringAsFixed(0)}g • ${widget.aiResult['size'] ?? 'Không xác định'}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
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
                      if (_nutritionSource != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _nutritionSource == 'local'
                                ? AppColors.success.withValues(alpha: 0.1)
                                : _nutritionSource == 'api'
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _nutritionSource == 'local'
                                ? 'Local'
                                : _nutritionSource == 'api'
                                    ? 'API'
                                    : 'Manual',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _nutritionSource == 'local'
                                  ? AppColors.success
                                  : _nutritionSource == 'api'
                                      ? AppColors.primary
                                      : AppColors.warning,
                              fontSize: 10,
                            ),
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

