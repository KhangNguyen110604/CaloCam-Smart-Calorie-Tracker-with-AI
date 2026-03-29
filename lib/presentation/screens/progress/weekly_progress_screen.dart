import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/datasources/local/shared_prefs_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';

/// Weekly Progress Screen
/// 
/// Shows user's weekly nutrition progress with:
/// - 7-day calorie bar chart
/// - Macro trends (Protein/Carbs/Fat)
/// - Weekly summary stats
/// - Weight tracking (TODO: Future implementation)
class WeeklyProgressScreen extends StatefulWidget {
  const WeeklyProgressScreen({super.key});

  @override
  State<WeeklyProgressScreen> createState() => _WeeklyProgressScreenState();
}

class _WeeklyProgressScreenState extends State<WeeklyProgressScreen> {
  Map<String, dynamic>? _userProfile;
  final List<_DayData> _weekData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load user profile and weekly meal data
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user ID
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        debugPrint('⚠️ WeeklyProgressScreen: No userId found');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Load user profile FOR THIS USER ONLY
      final user = await DatabaseHelper.instance.getUser(userId);
      
      // Load meal data for last 7 days
      final now = DateTime.now();
      final dbHelper = DatabaseHelper.instance;
      
      final weekData = <_DayData>[];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormatter.formatDate(date);
        
        // Get meals for this date FOR THIS USER ONLY
        final meals = await dbHelper.getMealsByDate(userId, dateStr);
        
        // Calculate totals
        double totalCalories = 0;
        double totalProtein = 0;
        double totalCarbs = 0;
        double totalFat = 0;
        
        for (final meal in meals) {
          totalCalories += (meal['calories'] as num).toDouble();
          totalProtein += (meal['protein'] as num).toDouble();
          totalCarbs += (meal['carbs'] as num).toDouble();
          totalFat += (meal['fat'] as num).toDouble();
        }
        
        weekData.add(_DayData(
          date: date,
          calories: totalCalories,
          protein: totalProtein,
          carbs: totalCarbs,
          fat: totalFat,
          mealCount: meals.length,
        ));
      }

      if (mounted) {
        setState(() {
          _userProfile = user;
          _weekData.clear();
          _weekData.addAll(weekData);
          _isLoading = false;
        });
      }
      
      debugPrint('✅ WeeklyProgressScreen: Loaded data for user $userId');
    } catch (e) {
      debugPrint('❌ WeeklyProgressScreen: Error loading weekly data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống kê tuần'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeeklySummary(),
                    const SizedBox(height: AppDimensions.marginLarge),
                    _buildCalorieChart(),
                    const SizedBox(height: AppDimensions.marginLarge),
                    _buildMacroTrends(),
                    const SizedBox(height: AppDimensions.marginLarge),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build weekly summary card with key metrics
  Widget _buildWeeklySummary() {
    // Calculate weekly totals and averages
    final totalCalories = _weekData.fold<double>(
      0,
      (sum, day) => sum + day.calories,
    );
    final avgCalories = _weekData.isNotEmpty ? totalCalories / 7 : 0;
    final daysWithMeals = _weekData.where((day) => day.mealCount > 0).length;
    
    final calorieGoal = _userProfile != null 
        ? (_userProfile!['calorie_goal'] as num).toDouble()
        : 2000.0;
    
    final avgProgress = (avgCalories / calorieGoal * 100).clamp(0, 100);

    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginLarge),
      padding: const EdgeInsets.all(AppDimensions.marginLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tóm tắt tuần này',
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  Icons.local_fire_department,
                  '${avgCalories.toInt()}',
                  'TB calo/ngày',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  Icons.calendar_today,
                  '$daysWithMeals/7',
                  'Ngày theo dõi',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  Icons.trending_up,
                  '${avgProgress.toInt()}%',
                  'Đạt mục tiêu',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual summary item
  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build 7-day calorie bar chart
  Widget _buildCalorieChart() {
    final calorieGoal = _userProfile != null 
        ? (_userProfile!['calorie_goal'] as num).toDouble()
        : 2000.0;
    
    // Find max value for scaling (ensure it's at least goal, or highest actual value)
    final maxCalories = _weekData.isEmpty
        ? calorieGoal
        : math.max(
            calorieGoal * 1.2, // Always show goal line properly
            _weekData.map((d) => d.calories).reduce(math.max),
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
      padding: const EdgeInsets.all(AppDimensions.marginLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calories 7 ngày', style: AppTextStyles.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 2,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mục tiêu: ${calorieGoal.toInt()}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          
          // Chart (increased height to accommodate labels)
          SizedBox(
            height: 230, // Increased from 200 to 230 to fit all labels
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _weekData.map((dayData) {
                return _buildCalorieBar(
                  dayData,
                  maxCalories,
                  calorieGoal,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual calorie bar for chart
  Widget _buildCalorieBar(_DayData dayData, double maxValue, double goal) {
    // Max bar height reduced to fit within 230px container (with labels)
    final height = (dayData.calories / maxValue * 160).clamp(4.0, 160.0);
    final isToday = DateFormatter.formatDate(dayData.date) == 
                    DateFormatter.formatDate(DateTime.now());
    final isOverGoal = dayData.calories > goal;
    
    Color barColor;
    if (dayData.calories == 0) {
      barColor = AppColors.border;
    } else if (isOverGoal) {
      barColor = AppColors.accent;
    } else {
      barColor = AppColors.primary;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Calorie value (with smart formatting)
            if (dayData.calories > 0)
              Text(
                _formatCalorieValue(dayData.calories),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: barColor,
                  fontSize: 10,
                ),
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
            const SizedBox(height: 4),
            
            // Bar
            Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dayData.calories == 0
                      ? [barColor, barColor]
                      : [barColor, barColor.withValues(alpha: 0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                border: isToday 
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            
            // Day label
            Text(
              _getWeekdayShort(dayData.date.weekday),
              style: AppTextStyles.bodySmall.copyWith(
                color: isToday ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build macro trends section (Protein/Carbs/Fat lines)
  Widget _buildMacroTrends() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
      padding: const EdgeInsets.all(AppDimensions.marginLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Xu hướng dinh dưỡng', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppDimensions.marginLarge),
          
          // Macro average cards
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  'Protein',
                  _calculateAverage((day) => day.protein),
                  AppColors.macroProtein,
                ),
              ),
              const SizedBox(width: AppDimensions.marginSmall),
              Expanded(
                child: _buildMacroCard(
                  'Carbs',
                  _calculateAverage((day) => day.carbs),
                  AppColors.macroCarbs,
                ),
              ),
              const SizedBox(width: AppDimensions.marginSmall),
              Expanded(
                child: _buildMacroCard(
                  'Fat',
                  _calculateAverage((day) => day.fat),
                  AppColors.macroFat,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          
          // Simple trend indicators
          _buildTrendRow(
            'Protein TB',
            _calculateAverage((day) => day.protein),
            _calculateTrend((day) => day.protein),
            AppColors.macroProtein,
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          _buildTrendRow(
            'Carbs TB',
            _calculateAverage((day) => day.carbs),
            _calculateTrend((day) => day.carbs),
            AppColors.macroCarbs,
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          _buildTrendRow(
            'Fat TB',
            _calculateAverage((day) => day.fat),
            _calculateTrend((day) => day.fat),
            AppColors.macroFat,
          ),
        ],
      ),
    );
  }

  /// Build macro average card
  Widget _buildMacroCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.marginMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${value.toInt()}g',
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build trend row with icon indicator
  Widget _buildTrendRow(String label, double value, double trend, Color color) {
    IconData trendIcon;
    Color trendColor;
    
    if (trend > 5) {
      trendIcon = Icons.trending_up;
      trendColor = Colors.green;
    } else if (trend < -5) {
      trendIcon = Icons.trending_down;
      trendColor = Colors.red;
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = Colors.grey;
    }

    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
        ),
        Icon(trendIcon, size: 20, color: trendColor),
        const SizedBox(width: 8),
        Text(
          '${value.toInt()}g',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Calculate average value across the week
  double _calculateAverage(double Function(_DayData) getValue) {
    if (_weekData.isEmpty) return 0;
    final total = _weekData.fold<double>(0, (sum, day) => sum + getValue(day));
    return total / 7; // Always divide by 7 to show daily average
  }

  /// Calculate trend (simple: compare last 3 days vs first 3 days)
  double _calculateTrend(double Function(_DayData) getValue) {
    if (_weekData.length < 6) return 0;
    
    final firstHalf = _weekData.take(3).fold<double>(
      0,
      (sum, day) => sum + getValue(day),
    ) / 3;
    
    final secondHalf = _weekData.skip(4).fold<double>(
      0,
      (sum, day) => sum + getValue(day),
    ) / 3;
    
    return secondHalf - firstHalf;
  }

  /// Get short weekday name in Vietnamese
  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  /// Format calorie value for chart labels (smart formatting for large numbers)
  /// 
  /// Examples:
  /// - 1420 → "1420"
  /// - 5730 → "5.7k"
  /// - 999 → "999"
  String _formatCalorieValue(double calories) {
    if (calories >= 10000) {
      return '${(calories / 1000).toStringAsFixed(0)}k'; // 12345 → "12k"
    } else if (calories >= 1000) {
      return '${(calories / 1000).toStringAsFixed(1)}k'; // 5730 → "5.7k"
    } else {
      return calories.toInt().toString(); // 999 → "999"
    }
  }
}

/// Data model for a single day's nutrition data
class _DayData {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int mealCount;

  _DayData({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealCount,
  });
}

