import 'package:flutter/material.dart';
import 'dart:io';
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/datasources/local/shared_prefs_helper.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';

/// Meal History Screen
/// 
/// Displays all meal entries with:
/// - Chronological list grouped by date
/// - Search by food name
/// - Filter by meal type (Breakfast, Lunch, Dinner, Snack)
/// - Navigation to meal details
class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  // Pagination state
  List<MealEntryModel> _allMeals = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentOffset = 0;
  final int _pageSize = 50; // Load 50 meals per page
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String? _selectedMealType; // null = all, 'breakfast', 'lunch', 'dinner', 'snack'
  
  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();
  
  // Total count (for showing "X of Y meals")
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialMeals();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll events for infinite scroll
  /// 
  /// Loads more data when user scrolls to bottom
  void _onScroll() {
    // Check if user scrolled near bottom (80% of scroll extent)
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreMeals();
    }
  }

  /// Load initial page of meals
  /// 
  /// Called on screen init and pull-to-refresh
  /// Resets pagination state and loads first page
  Future<void> _loadInitialMeals() async {
    setState(() {
      _isLoading = true;
      _currentOffset = 0;
      _hasMoreData = true;
    });

    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ MealHistoryScreen: No userId found');
        if (mounted) {
          setState(() {
            _allMeals = [];
            _isLoading = false;
          });
        }
        return;
      }

      final dbHelper = DatabaseHelper.instance;
      
      // Get total count for display
      _totalCount = await dbHelper.getMealsCount(
        mealType: _selectedMealType,
        searchQuery: _searchController.text.trim(),
      );
      
      // Load first page FOR THIS USER ONLY
      final mealMaps = await dbHelper.getMealsPaginated(
        userId: userId,
        limit: _pageSize,
        offset: 0,
        mealType: _selectedMealType,
        searchQuery: _searchController.text.trim(),
      );
      
      final meals = mealMaps
          .map((map) => MealEntryModel.fromMap(map))
          .toList();
      
      if (mounted) {
        setState(() {
          _allMeals = meals;
          _currentOffset = meals.length;
          _hasMoreData = meals.length >= _pageSize;
          _isLoading = false;
        });
        
        debugPrint('✅ Loaded ${meals.length} meals for user $userId (Total: $_totalCount)');
      }
    } catch (e) {
      debugPrint('❌ Error loading meal history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Load more meals (pagination)
  /// 
  /// Called when user scrolls near bottom
  /// Appends next page to existing list
  Future<void> _loadMoreMeals() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ MealHistoryScreen: No userId found for pagination');
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
        return;
      }

      final dbHelper = DatabaseHelper.instance;
      
      // Load next page FOR THIS USER ONLY
      final mealMaps = await dbHelper.getMealsPaginated(
        userId: userId,
        limit: _pageSize,
        offset: _currentOffset,
        mealType: _selectedMealType,
        searchQuery: _searchController.text.trim(),
      );
      
      final newMeals = mealMaps
          .map((map) => MealEntryModel.fromMap(map))
          .toList();
      
      if (mounted) {
        setState(() {
          _allMeals.addAll(newMeals);
          _currentOffset = _currentOffset + newMeals.length;
          _hasMoreData = newMeals.length >= _pageSize;
          _isLoadingMore = false;
        });
        
        debugPrint('✅ Loaded ${newMeals.length} more meals for user $userId (Total loaded: ${_allMeals.length}/$_totalCount)');
      }
    } catch (e) {
      debugPrint('❌ Error loading more meals: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  /// Handle search text changes
  /// 
  /// Debounced to avoid excessive database queries
  void _onSearchChanged() {
    // Reload from database with new search query
    _loadInitialMeals();
  }

  /// Toggle meal type filter
  /// 
  /// Reloads data from database with new filter
  void _toggleMealTypeFilter(String? mealType) {
    setState(() {
      _selectedMealType = mealType == _selectedMealType ? null : mealType;
    });
    // Reload from database with new filter
    _loadInitialMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử bữa ăn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildMealTypeFilters(),
          Expanded(
            child: _isLoading
                ? const ListLoadingSkeleton(itemCount: 8)
                : _allMeals.isEmpty
                    ? _buildEmptyState()
                    : _buildMealsList(),
          ),
        ],
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.marginLarge),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm món ăn...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginMedium,
            vertical: AppDimensions.marginSmall,
          ),
        ),
      ),
    );
  }

  /// Build meal type filter chips
  Widget _buildMealTypeFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.marginLarge,
        vertical: AppDimensions.marginSmall,
      ),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tất cả', null, Icons.restaurant_menu),
            const SizedBox(width: AppDimensions.marginSmall),
            _buildFilterChip('Bữa sáng', 'breakfast', Icons.wb_sunny_outlined),
            const SizedBox(width: AppDimensions.marginSmall),
            _buildFilterChip('Bữa trưa', 'lunch', Icons.wb_sunny),
            const SizedBox(width: AppDimensions.marginSmall),
            _buildFilterChip('Bữa tối', 'dinner', Icons.nightlight_round),
            const SizedBox(width: AppDimensions.marginSmall),
            _buildFilterChip('Ăn vặt', 'snack', Icons.cookie_outlined),
          ],
        ),
      ),
    );
  }

  /// Build individual filter chip
  Widget _buildFilterChip(String label, String? mealType, IconData icon) {
    final isSelected = _selectedMealType == mealType;
    final color = mealType != null 
        ? _getMealTypeColor(mealType)
        : AppColors.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _toggleMealTypeFilter(mealType),
      backgroundColor: color.withValues(alpha: 0.1),
      selectedColor: color,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: isSelected ? Colors.white : color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    final hasFilters = _searchController.text.isNotEmpty || _selectedMealType != null;
    
    if (hasFilters) {
      return NoSearchResultsEmptyState(
        searchQuery: _searchController.text.isEmpty 
            ? _selectedMealType ?? '' 
            : _searchController.text,
      );
    }
    
    return EmptyState(
      icon: Icons.history,
      title: 'Chưa có lịch sử',
      message: 'Lịch sử bữa ăn của bạn\nsẽ xuất hiện ở đây\n\nChụp ảnh hoặc thêm thủ công để bắt đầu',
      actionLabel: 'Thêm bữa ăn',
      onAction: () {
        Navigator.pushNamed(context, '/add-meal');
      },
    );
  }

  /// Build meals list grouped by date with infinite scroll
  Widget _buildMealsList() {
    // Group meals by date (convert DateTime to String for grouping)
    final groupedMeals = <String, List<MealEntryModel>>{};
    for (final meal in _allMeals) {
      final dateStr = DateFormatter.formatDate(meal.date);
      groupedMeals.putIfAbsent(dateStr, () => []).add(meal);
    }

    return RefreshIndicator(
      onRefresh: _loadInitialMeals,
      child: ListView.builder(
        controller: _scrollController, // Attach scroll controller for infinite scroll
        padding: const EdgeInsets.only(bottom: AppDimensions.marginLarge),
        // +1 for loading indicator at bottom (if loading more)
        itemCount: groupedMeals.length + (_isLoadingMore || !_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          // Show date sections
          if (index < groupedMeals.length) {
            final date = groupedMeals.keys.elementAt(index);
            final mealsForDate = groupedMeals[date]!;
            return _buildDateSection(date, mealsForDate);
          }
          
          // Show loading indicator or end message at bottom
          return _buildBottomWidget();
        },
      ),
    );
  }

  /// Build bottom widget (loading indicator or end message)
  Widget _buildBottomWidget() {
    if (_isLoadingMore) {
      // Loading more data
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.marginLarge),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppDimensions.marginSmall),
              Text(
                'Đang tải thêm...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (!_hasMoreData && _allMeals.isNotEmpty) {
      // No more data to load
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.marginLarge),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.primary.withValues(alpha: 0.3),
                size: 32,
              ),
              const SizedBox(height: AppDimensions.marginSmall),
              Text(
                'Đã tải hết $_totalCount bữa ăn',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_allMeals.length} bữa ăn đang hiển thị',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  /// Build date section with meals
  Widget _buildDateSection(String date, List<MealEntryModel> meals) {
    final dateTime = DateTime.parse(date);
    final isToday = DateFormatter.formatDate(DateTime.now()) == date;
    final isYesterday = DateFormatter.formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    ) == date;
    
    String dateLabel;
    if (isToday) {
      dateLabel = 'Hôm nay';
    } else if (isYesterday) {
      dateLabel = 'Hôm qua';
    } else {
      dateLabel = DateFormatter.formatDateWithWeekday(dateTime);
    }

    // Calculate total calories for this date
    final totalCalories = meals.fold<double>(
      0,
      (sum, meal) => sum + meal.calories,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginLarge,
            vertical: AppDimensions.marginMedium,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${totalCalories.toInt()} calo',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Meals for this date
        ...meals.map((meal) => _buildMealCard(meal)),
        
        const SizedBox(height: AppDimensions.marginSmall),
      ],
    );
  }

  /// Build individual meal card
  Widget _buildMealCard(MealEntryModel meal) {
    final mealColor = _getMealTypeColor(meal.mealType);
    final hasImage = meal.imagePath != null && meal.imagePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.marginLarge,
        vertical: AppDimensions.marginSmall / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to meal detail screen
            Navigator.pushNamed(
              context,
              '/meal-detail',
              arguments: meal.mealType,
            );
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.marginMedium),
            child: Row(
              children: [
                // Meal image or icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: mealColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          child: Image.file(
                            File(meal.imagePath!),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.restaurant,
                                color: mealColor,
                                size: 28,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          color: mealColor,
                          size: 28,
                        ),
                ),
                const SizedBox(width: AppDimensions.marginMedium),
                
                // Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              meal.foodName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (meal.source == 'ai') ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Meal type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: mealColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getMealTypeLabel(meal.mealType),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: mealColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meal.time,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Calories
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${meal.calories.toInt()}',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      'calo',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get color for meal type
  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
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

  /// Get label for meal type
  String _getMealTypeLabel(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Sáng';
      case 'lunch':
        return 'Trưa';
      case 'dinner':
        return 'Tối';
      case 'snack':
        return 'Vặt';
      default:
        return mealType;
    }
  }
}

