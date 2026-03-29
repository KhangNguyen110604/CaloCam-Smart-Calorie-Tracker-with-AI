import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math' as math;
import '../../../data/datasources/local/database_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/bmi_calculator.dart';

/// Weight Tracking Screen
/// 
/// Features:
/// - Log daily weight entries
/// - View weight history with trend chart
/// - Track BMI changes over time
/// - Progress towards goal weight
/// - Add notes for each entry
class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<Map<String, dynamic>> _weightHistory = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  
  // Chart view mode (7 days or 30 days)
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load user profile and weight history
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user profile
      _userProfile = await _db.getFirstUser();
      
      // Load weight history (last 90 days)
      if (_userProfile != null) {
        final userId = _userProfile!['id'] as int;
        final dbInstance = await _db.database;
        
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 90));
        
        _weightHistory = await dbInstance.query(
          'weight_history',
          where: 'user_id = ? AND date >= ? AND date <= ?',
          whereArgs: [
            userId,
            DateFormatter.formatDate(startDate),
            DateFormatter.formatDate(endDate),
          ],
          orderBy: 'date DESC',
        );
        
        debugPrint('✅ Loaded ${_weightHistory.length} weight entries');
      }
    } catch (e) {
      debugPrint('❌ Error loading weight data: $e');
    } finally {
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
        title: const Text('Theo dõi cân nặng'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWeightDialog,
            tooltip: 'Thêm cân nặng',
          ),
        ],
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
                    _buildCurrentStats(),
                    const SizedBox(height: AppDimensions.marginLarge),
                    _buildProgressCard(),
                    const SizedBox(height: AppDimensions.marginLarge),
                    _buildChartSection(),
                    const SizedBox(height: AppDimensions.marginLarge),
                    _buildWeightHistory(),
                    const SizedBox(height: AppDimensions.marginLarge * 2),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build current stats (latest weight, BMI, change)
  Widget _buildCurrentStats() {
    if (_userProfile == null) return const SizedBox.shrink();
    
    final currentWeight = (_userProfile!['weight_kg'] as num).toDouble();
    final heightCm = (_userProfile!['height_cm'] as num).toDouble();
    final bmi = BMICalculator.calculate(
      weightKg: currentWeight,
      heightCm: heightCm,
    );
    final bmiCategory = BMICalculator.getCategory(bmi);
    
    // Calculate weight change from first entry
    double weightChange = 0.0;
    if (_weightHistory.length >= 2) {
      final oldest = (_weightHistory.last['weight_kg'] as num).toDouble();
      weightChange = currentWeight - oldest;
    }

    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginLarge),
      padding: const EdgeInsets.all(AppDimensions.marginLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Cân nặng hiện tại',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currentWeight.toStringAsFixed(1)} kg',
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'BMI',
                bmi.toStringAsFixed(1),
                bmiCategory,
                Icons.monitor_weight,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                'Thay đổi',
                '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                _weightHistory.length >= 2 ? 'Tổng cộng' : 'Chưa đủ dữ liệu',
                weightChange < 0 ? Icons.trending_down : Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual stat item for current stats card
  Widget _buildStatItem(String label, String value, String subtitle, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
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
        ),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Build progress card (towards goal weight)
  Widget _buildProgressCard() {
    if (_userProfile == null) return const SizedBox.shrink();
    
    final goalType = _userProfile!['goal_type'] as String;
    final currentWeight = (_userProfile!['weight_kg'] as num).toDouble();
    final targetWeight = (_userProfile!['target_weight_kg'] as num?)?.toDouble();
    
    if (targetWeight == null || goalType == 'maintain') {
      return const SizedBox.shrink();
    }
    
    final totalDifference = (targetWeight - (_weightHistory.isNotEmpty 
        ? (_weightHistory.last['weight_kg'] as num).toDouble()
        : currentWeight)).abs();
    final currentDifference = (targetWeight - currentWeight).abs();
    final progress = totalDifference > 0
        ? ((totalDifference - currentDifference) / totalDifference).clamp(0.0, 1.0)
        : 0.0;

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
              Text(
                'Tiến trình mục tiêu',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
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
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Goal info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Còn lại: ${currentDifference.toStringAsFixed(1)} kg',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Mục tiêu: ${targetWeight.toStringAsFixed(1)} kg',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build chart section with day toggle
  Widget _buildChartSection() {
    if (_weightHistory.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
        padding: const EdgeInsets.all(AppDimensions.marginLarge * 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.show_chart,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu biểu đồ',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thêm cân nặng để xem xu hướng',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
              Text(
                'Biểu đồ cân nặng',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Day toggle buttons
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildDayToggle('7 ngày', 7),
                    _buildDayToggle('30 ngày', 30),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Simple line chart
          _buildSimpleLineChart(),
        ],
      ),
    );
  }

  /// Build day toggle button
  Widget _buildDayToggle(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDays = days);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Build simple line chart for weight trend
  Widget _buildSimpleLineChart() {
    // Filter data by selected days
    final now = DateTime.now();
    final filteredData = _weightHistory.where((entry) {
      final entryDate = DateTime.parse(entry['date'] as String);
      return now.difference(entryDate).inDays <= _selectedDays;
    }).toList().reversed.toList();

    if (filteredData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Không đủ dữ liệu cho khoảng thời gian này'),
        ),
      );
    }

    // Calculate min/max for scaling
    final weights = filteredData.map((e) => (e['weight_kg'] as num).toDouble()).toList();
    final minWeight = weights.reduce(math.min) - 1;
    final maxWeight = weights.reduce(math.max) + 1;
    final weightRange = maxWeight - minWeight;

    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _WeightChartPainter(
          data: filteredData,
          minWeight: minWeight,
          maxWeight: maxWeight,
          weightRange: weightRange,
        ),
        child: Container(),
      ),
    );
  }

  /// Build weight history list
  Widget _buildWeightHistory() {
    if (_weightHistory.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
        padding: const EdgeInsets.all(AppDimensions.marginLarge * 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có lịch sử cân nặng',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhấn + để thêm cân nặng',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.marginLarge),
          child: Text(
            'Lịch sử',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Weight entries list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: math.min(_weightHistory.length, 10), // Show max 10 recent entries
          itemBuilder: (context, index) {
            final entry = _weightHistory[index];
            final weight = (entry['weight_kg'] as num).toDouble();
            final date = DateTime.parse(entry['date'] as String);
            final note = entry['note'] as String?;
            
            // Calculate change from previous entry
            String changeText = '';
            if (index < _weightHistory.length - 1) {
              final prevWeight = (_weightHistory[index + 1]['weight_kg'] as num).toDouble();
              final change = weight - prevWeight;
              changeText = '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg';
            }

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.marginLarge,
                vertical: 4,
              ),
              padding: const EdgeInsets.all(AppDimensions.marginMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Date
                  Container(
                    width: 60,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          date.day.toString(),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Th${date.month}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Weight info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weight.toStringAsFixed(1)} kg',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (note != null && note.isNotEmpty)
                          Text(
                            note,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  
                  // Change indicator
                  if (changeText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: changeText.startsWith('+')
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        changeText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: changeText.startsWith('+')
                              ? AppColors.accent
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Show add weight dialog
  void _showAddWeightDialog() {
    final weightController = TextEditingController(
      text: _userProfile != null 
          ? (_userProfile!['weight_kg'] as num).toStringAsFixed(1)
          : '',
    );
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm cân nặng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cân nặng (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(weightController.text);
              if (weight == null || weight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập cân nặng hợp lệ')),
                );
                return;
              }

              try {
                final dbInstance = await _db.database;
                final userId = _userProfile!['id'] as int;
                final today = DateFormatter.formatDate(DateTime.now());

                // Insert weight history
                await dbInstance.insert(
                  'weight_history',
                  {
                    'user_id': userId,
                    'weight_kg': weight,
                    'date': today,
                    'note': noteController.text.trim(),
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );

                // Update user's current weight
                await _db.updateUser(userId, {'weight_kg': weight});

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã cập nhật cân nặng'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  _loadData(); // Reload data
                }
              } catch (e) {
                debugPrint('❌ Error saving weight: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Có lỗi xảy ra')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for simple weight chart
class _WeightChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double minWeight;
  final double maxWeight;
  final double weightRange;

  _WeightChartPainter({
    required this.data,
    required this.minWeight,
    required this.maxWeight,
    required this.weightRange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final weight = (data[i]['weight_kg'] as num).toDouble();
      final x = size.width * i / (data.length - 1);
      final y = size.height - ((weight - minWeight) / weightRange * size.height);
      points.add(Offset(x, y));
    }

    // Draw line
    if (points.length > 1) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(
        point,
        7,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

