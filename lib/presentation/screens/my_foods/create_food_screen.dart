import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/food_provider.dart';

/// Create Food Screen
/// 
/// Form for creating a new custom food manually
/// User inputs: name, portion size, calories, macros, optional image
/// 
/// Features:
/// - Form validation
/// - Real-time error display
/// - Option to add to favorites immediately
/// - Image picker (optional)
/// 
/// Navigation:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => const CreateFoodScreen(),
///   ),
/// );
/// ```
class CreateFoodScreen extends StatefulWidget {
  const CreateFoodScreen({super.key});

  @override
  State<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _portionController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  
  bool _addToFavorites = false;
  bool _isSubmitting = false;

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
        title: const Text('Tạo món ăn mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          children: [
            // Helper text
            _buildHelperCard(),
            
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
            
            // Calories (required)
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
              'Thông tin dinh dưỡng (tùy chọn)',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Để trống nếu không biết chính xác',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
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
            
            // Add to favorites checkbox
            SwitchListTile(
              value: _addToFavorites,
              onChanged: (value) => setState(() => _addToFavorites = value),
              title: const Text('Thêm vào Món yêu thích'),
              subtitle: const Text('Để truy cập nhanh sau này'),
              secondary: const Icon(Icons.favorite, color: AppColors.error),
              activeTrackColor: AppColors.primary,
            ),
            
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
                      backgroundColor: AppColors.primary,
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
                        : const Text('Tạo món'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build helper card
  Widget _buildHelperCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nhập thông tin dinh dưỡng cho 100g món ăn. Bạn có thể chỉnh sửa sau.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
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

  /// Show help dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hướng dẫn'),
        content: const Text(
          '• Nhập thông tin dinh dưỡng cho 100g món ăn\n'
          '• Chỉ có Tên và Calories là bắt buộc\n'
          '• Protein, Carbs, Fat có thể để 0 nếu không biết\n'
          '• Bật "Thêm vào Món yêu thích" để truy cập nhanh\n'
          '• Bạn có thể chỉnh sửa hoặc xóa món này sau',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  /// Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      
      // Create food
      final food = await foodProvider.createFood(
        name: _nameController.text.trim(),
        portionSize: double.parse(_portionController.text),
        calories: double.parse(_caloriesController.text),
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        source: 'manual',
      );

      if (food == null) {
        throw Exception('Không thể tạo món ăn');
      }

      // Add to favorites if checked
      if (_addToFavorites && mounted) {
        await foodProvider.toggleFavorite(food.id, 'custom');
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tạo món "${food.name}"'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Return to previous screen
        Navigator.pop(context, food);
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

