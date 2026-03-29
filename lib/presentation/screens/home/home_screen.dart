import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:io';
import '../../providers/meal_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/feature_tutorial_overlay.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/skeleton_loader.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/datasources/local/shared_prefs_helper.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../debug/debug_database_screen.dart';
import '../camera/camera_screen.dart';

/// Home Screen - Main dashboard with calorie tracking
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  int _streak = 0; // Daily streak counter
  
  // Global keys for tutorial targets
  final GlobalKey _cameraButtonKey = GlobalKey();
  // Unused keys for future tutorial enhancements
  // final GlobalKey _calorieRingKey = GlobalKey();
  // final GlobalKey _waterWidgetKey = GlobalKey();
  // final GlobalKey _mealChecklistKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
    // Show tutorial after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when dependencies change (e.g., after login/logout)
    // This ensures we always show the correct user's data
    _loadData();
  }
  
  /// Show tutorial for first-time users
  Future<void> _showTutorialIfNeeded() async {
    // Wait a bit for UI to settle
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      await QuickTutorial.showCameraIntro(context, _cameraButtonKey);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // IMPORTANT: Get current logged-in user's ID from SharedPreferences
      final userId = await SharedPrefsHelper.getUserId();
      
      if (userId == null) {
        debugPrint('⚠️ [HomeScreen] No userId found in SharedPreferences');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('🔍 [HomeScreen] Loading data for user ID: $userId');
      
      // Load user profile for the CURRENT logged-in user
      var user = await DatabaseHelper.instance.getUser(userId);
      
      if (user == null) {
        debugPrint('⚠️ [HomeScreen] User not found in database: $userId');
        setState(() => _isLoading = false);
        return;
      }
      
      debugPrint('✅ [HomeScreen] Loaded user: ${user['name']}');
      
      // Load today's meals and recent meals
      if (mounted) {
        final mealProvider = Provider.of<MealProvider>(context, listen: false);
        await mealProvider.loadTodayMeals();
        await mealProvider.loadRecentMeals();
      }

      // Calculate streak
      final streak = await _calculateStreak(userId);

      if (mounted) {
        setState(() {
          _userProfile = user;
          _streak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [HomeScreen] Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Calculate daily streak
  /// 
  /// Streak logic:
  /// - Count consecutive days with activity (meals or water intake)
  /// - If today has no activity → streak = 0
  /// - If today has activity → streak = 1, then check yesterday
  /// - If yesterday also has activity → streak++, continue checking
  /// - If any day is missed → stop counting
  Future<int> _calculateStreak(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final today = DateFormatter.formatDate(DateTime.now());
      
      // Get all unique dates with activity (meals OR water intake) for this user
      // Using UNION to combine meal dates and water dates
      final result = await db.rawQuery('''
        SELECT DISTINCT date 
        FROM (
          SELECT date FROM meal_entries WHERE user_id = ?
          UNION
          SELECT date FROM water_intake WHERE user_id = ? AND milliliters > 0
        )
        ORDER BY date DESC
      ''', [userId, userId]);
      
      if (result.isEmpty) {
        debugPrint('📊 [Streak] No activity found → streak = 0');
        return 0;
      }
      
      // Extract dates as List<String>
      final activeDates = result.map((row) => row['date'] as String).toList();
      
      debugPrint('📊 [Streak] Active dates: $activeDates');
      
      // Check if today has activity
      if (!activeDates.contains(today)) {
        debugPrint('📊 [Streak] No activity today → streak = 0');
        return 0;
      }
      
      // Count consecutive days starting from today
      int streak = 0;
      DateTime currentDate = DateTime.now();
      
      while (true) {
        final dateStr = DateFormatter.formatDate(currentDate);
        
        if (activeDates.contains(dateStr)) {
          streak++;
          // Move to previous day
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          // No activity on this day → stop counting
          break;
        }
        
        // Safety limit: don't go back more than 365 days
        if (streak >= 365) break;
      }
      
      debugPrint('📊 [Streak] Calculated streak: $streak days');
      return streak;
      
    } catch (e) {
      debugPrint('❌ [Streak] Error calculating: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header skeleton
                Container(
                  padding: const EdgeInsets.all(AppDimensions.marginLarge),
                  color: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: 150,
                        height: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonLoader(
                        width: 200,
                        height: 28,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.marginMedium),
                // Calorie ring skeleton
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
                  child: CalorieRingSkeleton(),
                ),
                const SizedBox(height: AppDimensions.marginLarge),
                // Stats skeleton
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
                  child: GridLoadingSkeleton(itemCount: 3),
                ),
                const SizedBox(height: AppDimensions.marginLarge),
                // Recent meals skeleton
                const ListLoadingSkeleton(itemCount: 3),
              ],
            ),
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không tìm thấy thông tin người dùng'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Xin chào người dùng
                _buildHeader(),
                const SizedBox(height: AppDimensions.marginMedium),
                
                // 2. Calo hôm nay (vòng tròn calo)
                _buildCalorieProgress(),
                const SizedBox(height: AppDimensions.marginLarge),
                
                // 3. Macros summary (Protein, Carbs, Fat)
                _buildMacrosSummary(),
                const SizedBox(height: AppDimensions.marginLarge),
                
                // 4. Quick stats (Mục tiêu, Kg/tuần, Ngày làm tốt)
                _buildQuickStats(),
                const SizedBox(height: AppDimensions.marginLarge),
                
                // 5. Bữa ăn hôm nay (Meal checklist) ← ĐÃ ĐẨY LÊN
                _buildMealChecklist(),
                const SizedBox(height: AppDimensions.marginLarge),
                
                // 6. Nước uống hôm nay ← ĐÃ ĐẨY XUỐNG
                _buildWaterIntakeWidget(),
                const SizedBox(height: AppDimensions.marginLarge),
                
                // 7. Gần đây (Recent meals)
                _buildRecentMeals(),
                const SizedBox(height: AppDimensions.marginLarge),
                
                // ❌ REMOVED: _buildQuickActions() - Hành động nhanh
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _cameraButtonKey, // For tutorial
        heroTag: 'home_camera_fab', // ✅ Unique hero tag
        onPressed: () {
          // Navigate to Camera Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text(
          'Chụp món ăn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userName = _userProfile!['name'] as String;
    final currentHour = DateTime.now().hour;
    String greeting = 'Chào buổi sáng';
    if (currentHour >= 12 && currentHour < 18) {
      greeting = 'Chào buổi chiều';
    } else if (currentHour >= 18) {
      greeting = 'Chào buổi tối';
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.marginLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              // Hidden debug menu - Long press greeting to open
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugDatabaseScreen(),
                ),
              );
            },
            child: Text(
              greeting,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userName,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieProgress() {
    final calorieGoal = (_userProfile!['calorie_goal'] as num).toDouble();
    
    return Consumer<MealProvider>(
      builder: (context, mealProvider, child) {
        final totalCalories = mealProvider.totalCalories;
        final progress = (totalCalories / calorieGoal).clamp(0.0, 1.0);
        final remaining = (calorieGoal - totalCalories).clamp(0.0, calorieGoal);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
          padding: const EdgeInsets.all(AppDimensions.marginLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calo hôm nay', style: AppTextStyles.titleMedium),
                  Text(
                    '${totalCalories.toInt()} / ${calorieGoal.toInt()}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.marginLarge),
              
              // Circular progress
              SizedBox(
                height: 200,
                child: CustomPaint(
                  painter: _CalorieProgressPainter(progress: progress),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${remaining.toInt()}',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                          ),
                        ),
                        Text(
                          'calo còn lại',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMacrosSummary() {
    return Consumer<MealProvider>(
      builder: (context, mealProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
          child: Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  'Protein',
                  mealProvider.totalProtein,
                  'g',
                  AppColors.macroProtein,
                  Icons.restaurant,
                ),
              ),
              const SizedBox(width: AppDimensions.marginMedium),
              Expanded(
                child: _buildMacroCard(
                  'Carbs',
                  mealProvider.totalCarbs,
                  'g',
                  AppColors.macroCarbs,
                  Icons.grain,
                ),
              ),
              const SizedBox(width: AppDimensions.marginMedium),
              Expanded(
                child: _buildMacroCard(
                  'Fat',
                  mealProvider.totalFat,
                  'g',
                  AppColors.macroFat,
                  Icons.water_drop,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMacroCard(String label, double value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.marginMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '${value.toInt()}$unit',
            style: AppTextStyles.titleMedium.copyWith(
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

  Widget _buildMealChecklist() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bữa ăn hôm nay', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimensions.marginMedium),
          
          Consumer<MealProvider>(
            builder: (context, mealProvider, child) {
              return Column(
                children: [
                  _buildMealTypeCard(
                    'Bữa sáng',
                    'breakfast',
                    Icons.wb_sunny_outlined,
                    mealProvider,
                  ),
                  const SizedBox(height: AppDimensions.marginSmall),
                  _buildMealTypeCard(
                    'Bữa trưa',
                    'lunch',
                    Icons.wb_sunny,
                    mealProvider,
                  ),
                  const SizedBox(height: AppDimensions.marginSmall),
                  _buildMealTypeCard(
                    'Bữa tối',
                    'dinner',
                    Icons.nightlight_round,
                    mealProvider,
                  ),
                  const SizedBox(height: AppDimensions.marginSmall),
                  _buildMealTypeCard(
                    'Ăn vặt',
                    'snack',
                    Icons.cookie_outlined,
                    mealProvider,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeCard(String title, String mealType, IconData icon, MealProvider provider) {
    final hasMeals = provider.hasMealsForType(mealType);
    final calories = provider.getCaloriesForType(mealType);
    final mealCount = provider.getMealsByType(mealType).length;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/meal-detail',
          arguments: mealType,
        );
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.marginMedium),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: hasMeals ? AppColors.primary : AppColors.border,
          width: hasMeals ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasMeals 
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              hasMeals ? Icons.check_circle : icon,
              color: hasMeals ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDimensions.marginMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: hasMeals ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasMeals) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$mealCount món • ${calories.toInt()} calo',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Chưa thêm món',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
      ),
    );
  }

  /// Build quick stats section (streak, avg calories, etc.)
  /// 
  /// Shows user's progress statistics in a compact format
  Widget _buildQuickStats() {
    return Consumer<MealProvider>(
      builder: (context, mealProvider, child) {
        final todayMeals = mealProvider.todayMeals;
        final mealCount = todayMeals.length;
        
        // Calculate average calories per meal (if any meals exist)
        final avgCalories = mealCount > 0 
            ? (mealProvider.totalCalories / mealCount).toInt()
            : 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
          padding: const EdgeInsets.all(AppDimensions.marginMedium),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.restaurant_menu,
                  mealCount.toString(),
                  'Món ăn',
                  AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.local_fire_department,
                  avgCalories.toString(),
                  'TB/món',
                  AppColors.accent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.emoji_events,
                  _streak.toString(),
                  'Ngày liên tục',
                  AppColors.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build recent meals section
  /// 
  /// Shows the last 3 meals with images from AI recognition
  /// Displays meals from any date, not just today
  /// Provides quick access to meal details and empty state
  Widget _buildRecentMeals() {
    return Consumer<MealProvider>(
      builder: (context, mealProvider, child) {
        // ✅ Get recent meals (last 3, regardless of date)
        final recentMeals = mealProvider.recentMeals;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gần đây', style: AppTextStyles.titleLarge),
                  // ✅ Show "Xem tất cả" if there are any recent meals
                  if (recentMeals.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/meal-history');
                      },
                      child: Text(
                        'Xem tất cả',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.marginMedium),
              
              // Empty state
              if (recentMeals.isEmpty)
                _buildEmptyRecentMeals()
              else
                // Recent meals list (up to 3 items) with animations
                ...recentMeals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final meal = entry.value;
                  return AnimatedListItem(
                    index: index,
                    child: _buildRecentMealItem(meal),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  /// Build empty state for recent meals
  /// 
  /// Shown when user hasn't added any meals yet
  Widget _buildEmptyRecentMeals() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.marginLarge * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Text(
            'Chưa có bữa ăn nào',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Text(
            'Chụp ảnh món ăn hoặc thêm thủ công\nđể bắt đầu theo dõi calories',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraScreen(),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp món ăn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.marginLarge,
                vertical: AppDimensions.marginMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build recent meal item card
  /// 
  /// Shows meal image (from AI), name, calories, and time
  /// Tappable to view meal details
  Widget _buildRecentMealItem(MealEntryModel meal) {
    final bool hasImage = meal.imagePath != null && meal.imagePath!.isNotEmpty;
    final mealColor = _getMealTypeColor(meal.mealType);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: mealColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          child: Image.file(
                            File(meal.imagePath!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.restaurant,
                                color: mealColor,
                                size: 32,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          color: mealColor,
                          size: 32,
                        ),
                ),
                const SizedBox(width: AppDimensions.marginMedium),
                
                // Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              meal.foodName,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (meal.source == 'ai') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              // ✅ Show relative date (e.g., "Hôm nay", "Hôm qua", "20/10")
                              DateFormatter.formatRelativeDate(meal.date),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            // ✅ Show time
                            meal.time,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${meal.calories.toInt()} calo',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get color for meal type
  /// 
  /// Returns appropriate color based on meal type (breakfast, lunch, dinner, snack)
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

  // ❌ REMOVED: _buildQuickActions() and _buildActionButton()
  // These methods are no longer used as quick actions section was removed

  /// Build water intake widget
  /// 
  /// Displays daily water intake progress with quick add buttons
  /// Provides visual feedback and easy tracking
  Widget _buildWaterIntakeWidget() {
    return Consumer<WaterProvider>(
      builder: (context, waterProvider, child) {
        final progress = waterProvider.progress.clamp(0.0, 1.0);
        final isGoalReached = waterProvider.isGoalReached;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
          padding: const EdgeInsets.all(AppDimensions.marginLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4FC3F7).withValues(alpha: 0.1),
                const Color(0xFF29B6F6).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          color: Color(0xFF0277BD),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nước uống hôm nay',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isGoalReached)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đạt mục tiêu',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4FC3F7),
                            Color(0xFF0277BD),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${waterProvider.currentIntake} ml / ${waterProvider.dailyGoal} ml',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0277BD),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0277BD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick add buttons row
              Row(
                children: [
                  Expanded(
                    child: _buildWaterButton(
                      '200ml',
                      Icons.water_drop_outlined,
                      () => waterProvider.addWater(200),
                      isAdd: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildWaterButton(
                      '500ml',
                      Icons.local_drink,
                      () => waterProvider.addWater(500),
                      isAdd: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildWaterButton(
                      '1000ml',
                      Icons.sports_bar,
                      () => waterProvider.addWater(1000),
                      isAdd: true,
                    ),
                  ),
                ],
              ),
              
              // ✨ NEW: Undo/Decrease button row
              if (waterProvider.currentIntake > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildWaterButton(
                        'Hoàn tác',
                        Icons.undo_rounded,
                        () {
                          // Undo last add (default 200ml or custom)
                          final amountToRemove = waterProvider.currentIntake >= 200 ? 200 : waterProvider.currentIntake;
                          waterProvider.removeWater(amountToRemove);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã giảm ${amountToRemove}ml 💧'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        isAdd: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildWaterButton(
                        '-500ml',
                        Icons.remove_circle_outline,
                        () {
                          if (waterProvider.currentIntake >= 500) {
                            waterProvider.removeWater(500);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã giảm 500ml 💧'),
                                duration: Duration(seconds: 1),
                                backgroundColor: Colors.deepOrange,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không đủ để giảm 500ml'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        isAdd: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildWaterButton(
                        'Đặt lại',
                        Icons.refresh_rounded,
                        () {
                          waterProvider.resetTodayIntake();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đặt lại về 0ml 💧'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        isAdd: false,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Build water quick add/remove button
  /// 
  /// Small button for adding or removing water amounts
  /// [isAdd] - true for add (blue), false for remove (orange/red)
  Widget _buildWaterButton(
    String label, 
    IconData icon, 
    VoidCallback onTap, 
    {bool isAdd = true}
  ) {
    // Different colors for add vs remove
    final buttonColor = isAdd 
        ? const Color(0xFF4FC3F7)  // Blue for add
        : Colors.orange;            // Orange for remove
    
    final iconColor = isAdd 
        ? const Color(0xFF0277BD)  // Dark blue for add
        : Colors.deepOrange;        // Deep orange for remove
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: buttonColor.withValues(alpha: 0.3),
            ),
            color: isAdd 
                ? null 
                : buttonColor.withValues(alpha: 0.05), // Light bg for remove
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for circular calorie progress indicator
class _CalorieProgressPainter extends CustomPainter {
  final double progress;

  _CalorieProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
