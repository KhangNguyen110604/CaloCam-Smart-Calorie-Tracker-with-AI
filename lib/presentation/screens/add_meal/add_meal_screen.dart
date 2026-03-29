import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/food_model.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../../data/models/unified_food_model.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/datasources/local/shared_prefs_helper.dart';
import '../../providers/food_provider.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/unified_food_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import 'package:uuid/uuid.dart';

/// Add Meal Screen - Tap to Select Portion + Suggestions
/// 
/// NEW: Added 2 tabs:
/// - Tab 1 "Gợi ý": Favorite foods + recent foods (with ⭐)
/// - Tab 2 "Tìm kiếm": All foods search (original)
/// 
/// Flow:
/// 1. User sees suggestions first (favorites + recent)
/// 2. Can tap ⭐ to toggle favorite
/// 3. Or switch to search tab to find all foods
/// 4. Tap on food → Bottom sheet with portion options
/// 5. Select portion → Add immediately
class AddMealScreen extends StatefulWidget {
  final String mealType;

  const AddMealScreen({
    super.key,
    required this.mealType,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> with SingleTickerProviderStateMixin {
  // ==================== STATE VARIABLES ====================
  
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<FoodModel> _allFoods = [];
  List<FoodModel> _filteredFoods = [];
  bool _isLoading = true;
  int _addedCount = 0; // Track how many items added

  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFoods();
    _loadSuggestions(); // NEW: Load suggestions for tab 1
    _loadFavorites(); // NEW: Load favorites for star status
    _searchController.addListener(_filterFoods);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==================== DATA LOADING ====================

  /// NEW: Load suggestions for tab 1 (favorites + recent)
  Future<void> _loadSuggestions() async {
    final foodProvider = context.read<FoodProvider>();
    await foodProvider.loadSuggestionsForMeal(
      widget.mealType.toLowerCase(),
      limit: 20,
    );
  }

  /// NEW: Load favorites to check star status in search tab
  Future<void> _loadFavorites() async {
    final foodProvider = context.read<FoodProvider>();
    await foodProvider.loadFavorites();
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.ensureFoodsSeeded();
      final foodMaps = await DatabaseHelper.instance.getAllFoods();
      final foods = foodMaps.map((map) => FoodModel.fromMap(map)).toList();
      
      setState(() {
        _allFoods = foods;
        _filteredFoods = foods;
        _isLoading = false;
      });
      
      // ✨ NEW: Sort foods after loading to show favorites first
      // Wait a bit for FoodProvider to load favorites
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _filterFoods(); // This will sort favorites to top
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Show error with rebuild option
        _showDatabaseErrorDialog();
      }
    }
  }

  /// Show database error dialog with rebuild option
  void _showDatabaseErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(width: 12),
            const Text('Lỗi Database'),
          ],
        ),
        content: const Text(
          'Database cần được cập nhật.\n\n'
          'Bạn có muốn rebuild database không?\n'
          '(Dữ liệu cũ sẽ bị xóa)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rebuildDatabase();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Rebuild Database'),
          ),
        ],
      ),
    );
  }

  /// Rebuild database
  Future<void> _rebuildDatabase() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang rebuild database...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Delete old database
      await DatabaseHelper.instance.deleteDB();
      
      // Reinitialize (will create with new schema)
      await DatabaseHelper.instance.ensureFoodsSeeded();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessSnackBar('Database đã được rebuild thành công!');
        _loadFoods(); // Reload foods
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Lỗi rebuild database: $e');
      }
    }
  }

  void _filterFoods() {
    final query = _searchController.text.toLowerCase().trim();
    final foodProvider = context.read<FoodProvider>();
    
    setState(() {
      List<FoodModel> filtered;
      
      if (query.isEmpty) {
        filtered = _allFoods;
      } else {
        filtered = _allFoods.where((food) {
          return food.name.toLowerCase().contains(query) ||
                 food.nameEn.toLowerCase().contains(query) ||
                 food.category.toLowerCase().contains(query);
        }).toList();
      }
      
      // ✨ NEW: Sort favorites to top
      filtered.sort((a, b) {
        final aId = a.id.toString();
        final bId = b.id.toString();
        final aIsFavorite = foodProvider.favorites.any(
          (f) => f.id == aId && f.source == 'builtin',
        );
        final bIsFavorite = foodProvider.favorites.any(
          (f) => f.id == bId && f.source == 'builtin',
        );
        
        // Favorites first (true > false = -1)
        if (aIsFavorite && !bIsFavorite) return -1;
        if (!aIsFavorite && bIsFavorite) return 1;
        
        // If both same favorite status, keep original order (by name)
        return a.name.compareTo(b.name);
      });
      
      _filteredFoods = filtered;
    });
  }

  // ==================== MEAL ADDING LOGIC ====================

  /// Add meal with specified portion
  /// 
  /// ⚠️ CRITICAL: Uses userId from SharedPrefs for data isolation
  Future<void> _addMeal(FoodModel food, double portionMultiplier) async {
    try {
      // Get MealProvider before any async operations
      final mealProvider = context.read<MealProvider>();
      
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        throw Exception('Không tìm thấy user ID. Vui lòng đăng nhập lại.');
      }

      final now = DateTime.now();
      final mealEntry = {
        'id': const Uuid().v4(),
        'user_id': userId, // ✅ Dynamic user ID
        'food_id': food.id,
        'food_name': food.name,
        'meal_type': widget.mealType.toLowerCase(),
        'date': now.toIso8601String().split('T')[0],
        'time': _getCurrentTime(),
        'calories': food.calories * portionMultiplier,
        'protein': food.protein * portionMultiplier,
        'carbs': food.carbs * portionMultiplier,
        'fat': food.fat * portionMultiplier,
        'portion_size': food.portionSize,
        'portion_multiplier': portionMultiplier,
        'serving_size': food.servingSize * portionMultiplier,
        'servings': portionMultiplier,
        'source': 'manual',
        'image_path': food.imageUrl, // ✅ FIX: Use food's image (column: image_path)
        'confidence': null,
        'created_at': now.toIso8601String(),
      };

      // Convert Map to MealEntryModel
      final meal = MealEntryModel.fromMap(mealEntry);

      // Use MealProvider to add meal (this will sync to Firestore)
      await mealProvider.addMealEntry(meal);
      
      debugPrint('✅ [AddMeal] Added meal for user $userId: ${food.name} (${widget.mealType})');
      
      setState(() {
        _addedCount++;
      });
      
      if (mounted) {
        _showSuccessSnackBar(
          'Đã thêm ${food.name} (${_getPortionLabel(portionMultiplier)})',
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding meal: $e');
      if (mounted) {
        // Check if it's a database schema error
        if (e.toString().contains('no column') || 
            e.toString().contains('mismatch') ||
            e.toString().contains('statement aborts')) {
          _showDatabaseErrorDialog();
        } else {
          _showErrorSnackBar('Lỗi: $e');
        }
      }
    }
  }

  /// Show portion selection bottom sheet
  void _showPortionSelector(FoodModel food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _PortionSelectorSheet(
        food: food,
        mealColor: _getMealColor(),
        onAddPortion: (portion, {bool autoClose = true}) async {
          // Add meal first (this will update the UI)
          await _addMeal(food, portion);
          // Only close sheet if autoClose is true (for quick buttons)
          // Custom input will handle closing both sheets itself
          if (autoClose && mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// NEW: Show portion selector for UnifiedFoodModel (from suggestions tab)
  void _showPortionSelectorForUnified(UnifiedFoodModel unifiedFood) {
    // Convert UnifiedFoodModel to FoodModel for portion selector
    final food = FoodModel(
      id: int.tryParse(unifiedFood.id) ?? 0, // Parse ID from string
      name: unifiedFood.name,
      nameEn: unifiedFood.name, // Fallback
      calories: unifiedFood.calories,
      protein: unifiedFood.protein,
      carbs: unifiedFood.carbs,
      fat: unifiedFood.fat,
      portionSize: '${unifiedFood.portionSize.toStringAsFixed(0)}g', // Convert double to String
      servingSize: unifiedFood.servingSize ?? 1.0,
      category: 'General',
      imageUrl: unifiedFood.imagePath, // Use imagePath instead of imageUrl
    );
    _showPortionSelector(food);
  }

  /// NEW: Toggle favorite for UnifiedFoodModel (from suggestions tab)
  Future<void> _toggleFavoriteForUnified(UnifiedFoodModel food) async {
    final foodProvider = context.read<FoodProvider>();
    
    // Toggle favorite
    await foodProvider.toggleFavorite(food.id, food.foodSource);
    
    // Auto-refresh suggestions to reflect changes
    await _loadSuggestions();
    
    // Show feedback
    if (mounted) {
      final isFavorite = !food.isFavorite;
      _showSuccessSnackBar(
        isFavorite ? 'Đã thêm vào yêu thích ⭐' : 'Đã bỏ khỏi yêu thích',
      );
    }
  }

  /// NEW: Toggle favorite for FoodModel (from search tab)
  Future<void> _toggleFavoriteForFoodModel(FoodModel food) async {
    final foodProvider = context.read<FoodProvider>();
    
    // Toggle favorite using foodId and foodSource
    final foodId = food.id.toString();
    final foodSource = 'builtin'; // Search tab only shows built-in foods
    
    await foodProvider.toggleFavorite(foodId, foodSource);
    
    // Reload favorites to update UI in search tab
    await foodProvider.loadFavorites();
    
    // Auto-refresh suggestions tab to reflect changes
    await _loadSuggestions();
    
    // ✨ NEW: Re-sort search list to move favorites to top
    _filterFoods();
    
    // Show feedback
    if (mounted) {
      final isFavorite = foodProvider.favorites.any(
        (f) => f.id == foodId && f.source == 'builtin',
      );
      _showSuccessSnackBar(
        isFavorite ? 'Đã thêm vào yêu thích ⭐' : 'Đã bỏ khỏi yêu thích',
      );
    }
  }

  // ==================== HELPER METHODS ====================

  Color _getMealColor() {
    switch (widget.mealType.toLowerCase()) {
      case 'breakfast': return AppColors.breakfast;
      case 'lunch': return AppColors.lunch;
      case 'dinner': return AppColors.dinner;
      case 'snack': return AppColors.snack;
      default: return AppColors.primary;
    }
  }

  String _getMealTitle() {
    switch (widget.mealType.toLowerCase()) {
      case 'breakfast': return 'Bữa Sáng';
      case 'lunch': return 'Bữa Trưa';
      case 'dinner': return 'Bữa Tối';
      case 'snack': return 'Ăn Vặt';
      default: return 'Bữa Ăn';
    }
  }

  String _getPortionLabel(double multiplier) {
    if (multiplier == 0.5) return 'Nhỏ';
    if (multiplier == 1.0) return 'Vừa';
    if (multiplier == 1.5) return 'Lớn';
    return '${multiplier}x';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackBar(String message) {
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
                message,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
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

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(), // NEW: Tab bar
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuggestionsTab(), // NEW: Tab 1 - Gợi ý
                _buildSearchTab(),      // Tab 2 - Tìm kiếm (old content)
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _getMealColor(),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context, _addedCount > 0),
      ),
      title: Text(
        'Thêm món - ${_getMealTitle()}',
        style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
      ),
      actions: [
        if (_addedCount > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Đã thêm: $_addedCount',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _getMealColor(),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        AppDimensions.paddingL,
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tìm món ăn...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: _searchController.clear,
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// NEW: Tab bar for switching between Suggestions and Search
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _getMealColor(),
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: _getMealColor(),
        indicatorWeight: 3,
        labelStyle: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.titleSmall,
        tabs: const [
          Tab(
            icon: Icon(Icons.star_outline),
            text: 'Gợi ý',
          ),
          Tab(
            icon: Icon(Icons.search),
            text: 'Tìm kiếm',
          ),
        ],
      ),
    );
  }

  /// NEW: Suggestions tab - Shows favorites + recent foods
  Widget _buildSuggestionsTab() {
    return Consumer<FoodProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const ListLoadingSkeleton();
        }

        if (provider.suggestions.isEmpty) {
          return EmptyState(
            icon: Icons.star_outline,
            title: 'Chưa có gợi ý',
            message: 'Thêm món vào yêu thích để xem gợi ý tại đây',
            actionLabel: 'Tìm món ăn',
            onAction: () => _tabController.animateTo(1),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadSuggestions,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: provider.suggestions.length,
            itemBuilder: (context, index) {
              final food = provider.suggestions[index];
              return UnifiedFoodCard(
                food: food,
                showFavoriteButton: true, // ← Hiển thị nút ⭐
                accentColor: _getMealColor(), // NEW: Pass meal color
                onTap: () => _showPortionSelectorForUnified(food),
                onFavoriteToggle: () => _toggleFavoriteForUnified(food),
              );
            },
          ),
        );
      },
    );
  }

  /// Search tab - Original food list with search
  Widget _buildSearchTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredFoods.isEmpty) {
      return _buildEmptyState();
    }

    return _buildFoodList();
  }

  Widget _buildFoodList() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: _filteredFoods.length,
          itemBuilder: (context, index) {
            final food = _filteredFoods[index];
            
            // Convert FoodModel to UnifiedFoodModel for consistent UI
            final foodId = food.id.toString();
            final isFavorite = foodProvider.favorites.any(
              (f) => f.id == foodId && f.source == 'builtin',
            );
            
            final unifiedFood = UnifiedFoodModel.fromBuiltIn(
              food,
              isFavorite: isFavorite,
            );
            
            return UnifiedFoodCard(
              food: unifiedFood,
              showFavoriteButton: true,
              showSourceChip: false, // Hide source chip in search (all are built-in)
              accentColor: _getMealColor(), // Use meal color
              onTap: () => _showPortionSelector(food),
              onFavoriteToggle: () => _toggleFavoriteForFoodModel(food),
            );
          },
        );
      },
    );
  }

  // ==================== OLD CODE REMOVED ====================
  // _buildFoodCard() and _buildMacroTag() removed - now using UnifiedFoodCard for consistency

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Không tìm thấy món ăn',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PORTION SELECTOR SHEET ====================

/// Bottom sheet for selecting portion size
/// Shows: Nhỏ (0.5x), Vừa (1.0x), Lớn (1.5x), Tùy chỉnh
class _PortionSelectorSheet extends StatelessWidget {
  final FoodModel food;
  final Color mealColor;
  final Function(double portion, {bool autoClose}) onAddPortion;

  const _PortionSelectorSheet({
    required this.food,
    required this.mealColor,
    required this.onAddPortion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
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
          
          // Food info
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: mealColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(Icons.restaurant, color: mealColor, size: 30),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${food.calories.toStringAsFixed(0)} kcal / ${food.portionSize}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          Text(
            'Chọn khẩu phần:',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          
          // Portion buttons grid
          Row(
            children: [
              Expanded(
                child: _buildPortionButton(
                  context,
                  'Nhỏ',
                  '0.5x',
                  food.calories * 0.5,
                  () => onAddPortion(0.5),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Expanded(
                child: _buildPortionButton(
                  context,
                  'Vừa',
                  '1.0x',
                  food.calories * 1.0,
                  () => onAddPortion(1.0),
                  isPrimary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Row(
            children: [
              Expanded(
                child: _buildPortionButton(
                  context,
                  'Lớn',
                  '1.5x',
                  food.calories * 1.5,
                  () => onAddPortion(1.5),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Expanded(
                child: _buildCustomButton(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortionButton(
    BuildContext context,
    String label,
    String multiplier,
    double calories,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    final color = isPrimary ? mealColor : mealColor.withValues(alpha: 0.1);
    final textColor = isPrimary ? Colors.white : mealColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: mealColor,
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              multiplier,
              style: AppTextStyles.bodySmall.copyWith(
                color: isPrimary 
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${calories.toStringAsFixed(0)} kcal',
              style: AppTextStyles.bodySmall.copyWith(
                color: isPrimary 
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // Don't pop the main sheet - just show custom input on top
        _showCustomInput(context);
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(
              'Tùy chỉnh',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Tự nhập',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomInput(BuildContext parentContext) {
    final controller = TextEditingController(text: '1.0');
    
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (customContext) => _CustomPortionInput(
        food: food,
        mealColor: mealColor,
        controller: controller,
        onAdd: (portion) {
          debugPrint('🔧 Custom portion selected: $portion');
          // Call parent callback with autoClose: false
          // The custom input button will handle closing both sheets
          onAddPortion(portion, autoClose: false);
        },
      ),
    );
  }
}

// ==================== CUSTOM PORTION INPUT ====================

class _CustomPortionInput extends StatefulWidget {
  final FoodModel food;
  final Color mealColor;
  final TextEditingController controller;
  final Function(double) onAdd;

  const _CustomPortionInput({
    required this.food,
    required this.mealColor,
    required this.controller,
    required this.onAdd,
  });

  @override
  State<_CustomPortionInput> createState() => _CustomPortionInputState();
}

class _CustomPortionInputState extends State<_CustomPortionInput> {
  late double _portion;

  @override
  void initState() {
    super.initState();
    _portion = double.tryParse(widget.controller.text) ?? 1.0;
  }

  void _updatePortion(double delta) {
    setState(() {
      _portion = (_portion + delta).clamp(0.1, 10.0);
      widget.controller.text = _portion.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
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
          // Handle
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
          
          Text(
            widget.food.name,
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          
          // Portion input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _updatePortion(-0.5),
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 40,
                color: widget.mealColor,
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: widget.controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: widget.mealColor,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffix: Text('x', style: AppTextStyles.titleMedium),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    final p = double.tryParse(value);
                    if (p != null) setState(() => _portion = p.clamp(0.1, 10.0));
                  },
                ),
              ),
              IconButton(
                onPressed: () => _updatePortion(0.5),
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 40,
                color: widget.mealColor,
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          // Nutrition preview
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: widget.mealColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrient('Calo', widget.food.calories * _portion, AppColors.secondary),
                _buildNutrient('Protein', widget.food.protein * _portion, AppColors.macroProtein),
                _buildNutrient('Carbs', widget.food.carbs * _portion, AppColors.macroCarbs),
                _buildNutrient('Fat', widget.food.fat * _portion, AppColors.macroFat),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final p = double.tryParse(widget.controller.text) ?? 1.0;
                debugPrint('🔘 Add button pressed with portion: $p');
                if (p > 0) {
                  debugPrint('🔧 Calling onAdd callback...');
                  // Call callback to add meal (this will update UI)
                  widget.onAdd(p);
                  // Wait a bit for the meal to be added
                  await Future.delayed(const Duration(milliseconds: 150));
                  // Close BOTH sheets: custom input sheet + portion selector sheet
                  if (context.mounted) {
                    Navigator.pop(context); // Close custom input
                    await Future.delayed(const Duration(milliseconds: 50));
                    if (context.mounted) {
                      Navigator.pop(context); // Close portion selector
                    }
                  }
                } else {
                  debugPrint('❌ Invalid portion: $p');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.mealColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              child: Text(
                'Thêm vào bữa ăn',
                style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrient(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label == 'Calo' ? value.toStringAsFixed(0) : '${value.toStringAsFixed(1)}g',
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
}
