import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/user_food_model.dart';
import '../../providers/food_provider.dart';

/// Edit Food Screen
/// 
/// Form for editing an existing custom food
/// Pre-fills all fields with current values
/// Only editable foods (isEditable = true) can use this screen
/// 
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => EditFoodScreen(food: userFoodModel),
///   ),
/// );
/// ```
class EditFoodScreen extends StatefulWidget {
  final UserFoodModel food;

  const EditFoodScreen({
    super.key,
    required this.food,
  });

  @override
  State<EditFoodScreen> createState() => _EditFoodScreenState();
}

class _EditFoodScreenState extends State<EditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers - will be initialized in initState
  late TextEditingController _nameController;
  late TextEditingController _portionController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill controllers with existing values
    _nameController = TextEditingController(text: widget.food.name);
    _portionController = TextEditingController(text: widget.food.portionSize.toString());
    _caloriesController = TextEditingController(text: widget.food.calories.toString());
    _proteinController = TextEditingController(text: widget.food.protein.toString());
    _carbsController = TextEditingController(text: widget.food.carbs.toString());
    _fatController = TextEditingController(text: widget.food.fat.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chỉnh sửa món ăn'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          children: [
            // Info card showing source
            _buildInfoCard(),
            
            const SizedBox(height: AppDimensions.marginLarge),
            
            // Food name
            _buildTextField(
              controller: _nameController,
              label: 'Tên món ăn *',
              hint: 'VD: Phở gà nhà tôi',
              icon: Icons.restaurant,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên món ăn';
                }
                if (value.length < 2) {
                  return 'Tên món ăn quá ngắn';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppDimensions.marginMedium),
            
            // Portion size
            _buildTextField(
              controller: _portionController,
              label: 'Khẩu phần (gram)',
              hint: '100',
              icon: Icons.scale,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập khẩu phần';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return 'Khẩu phần phải > 0';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppDimensions.marginMedium),
            
            // Calories
            _buildTextField(
              controller: _caloriesController,
              label: 'Calories *',
              hint: '0',
              icon: Icons.local_fire_department,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập calories';
                }
                final num = double.tryParse(value);
                if (num == null || num < 0) {
                  return 'Calories không hợp lệ';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppDimensions.marginLarge),
            
            // Macros section
            Text(
              'Thông tin dinh dưỡng',
              style: AppTextStyles.titleMedium,
            ),
            
            const SizedBox(height: AppDimensions.marginMedium),
            
            // Protein, Carbs, Fat in row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _proteinController,
                    label: 'Protein (g)',
                    hint: '0',
                    icon: Icons.fitness_center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _carbsController,
                    label: 'Carbs (g)',
                    hint: '0',
                    icon: Icons.grain,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _fatController,
                    label: 'Fat (g)',
                    hint: '0',
                    icon: Icons.water_drop,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.marginLarge),
            
            // Usage statistics
            _buildUsageStats(),
            
            const SizedBox(height: AppDimensions.marginLarge),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Lưu thay đổi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build info card showing source
  Widget _buildInfoCard() {
    final sourceText = widget.food.source == 'ai_scan' ? 'Từ AI' : 'Thủ công';
    final icon = widget.food.source == 'ai_scan' ? Icons.auto_awesome : Icons.edit;
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguồn: $sourceText',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tạo: ${_formatDate(widget.food.createdAt)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build usage statistics
  Widget _buildUsageStats() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê sử dụng',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.history, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Đã dùng: ${widget.food.usageCount} lần',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          if (widget.food.lastUsedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Lần cuối: ${_formatDate(widget.food.lastUsedAt!)}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Hôm nay';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Confirm delete
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa món ăn?'),
        content: Text(
          'Bạn có chắc muốn xóa "${widget.food.name}"?\n\n'
          'Món ăn sẽ bị xóa khỏi danh sách của bạn và món yêu thích (nếu có).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteFood();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  /// Delete food
  Future<void> _deleteFood() async {
    setState(() => _isSubmitting = true);

    try {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      final success = await foodProvider.deleteFood(widget.food.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã xóa "${widget.food.name}"'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      } else if (mounted) {
        throw Exception('Không thể xóa món ăn');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      
      // Create updated food model
      final updatedFood = widget.food.copyWith(
        name: _nameController.text.trim(),
        portionSize: double.parse(_portionController.text),
        calories: double.parse(_caloriesController.text),
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
      );

      final success = await foodProvider.updateFood(updatedFood);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã cập nhật "${updatedFood.name}"'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, updatedFood);
      } else if (mounted) {
        throw Exception('Không thể cập nhật món ăn');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

