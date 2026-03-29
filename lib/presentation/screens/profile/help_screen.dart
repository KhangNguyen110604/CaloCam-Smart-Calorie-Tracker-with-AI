import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Help Screen
/// 
/// Displays FAQ (Frequently Asked Questions) to help users
/// understand how to use the app.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trợ giúp'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.marginLarge),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.marginLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Câu hỏi thường gặp',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tìm câu trả lời cho các thắc mắc của bạn',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.marginLarge),
          
          // FAQ Section: Sử dụng cơ bản
          _buildSectionTitle('Sử dụng cơ bản'),
          _buildFAQItem(
            question: 'Làm sao để chụp ảnh món ăn?',
            answer: 'Nhấn vào nút Camera ở giữa màn hình chính. Chụp ảnh món ăn của bạn, sau đó AI sẽ tự động nhận diện và tính toán dinh dưỡng.',
            icon: Icons.camera_alt,
          ),
          _buildFAQItem(
            question: 'Làm sao để thêm món ăn thủ công?',
            answer: 'Vào tab "Yêu thích", chọn "Món ăn của tôi", sau đó nhấn nút [+] để tạo món ăn mới với thông tin dinh dưỡng tùy chỉnh.',
            icon: Icons.add_circle_outline,
          ),
          _buildFAQItem(
            question: 'Làm sao để xem lịch sử bữa ăn?',
            answer: 'Ở màn hình chính, cuộn xuống phần "Gần đây" để xem các bữa ăn đã ghi. Hoặc vào tab "Thống kê" để xem chi tiết theo tuần.',
            icon: Icons.history,
          ),
          
          const SizedBox(height: AppDimensions.marginLarge),
          
          // FAQ Section: Quản lý dữ liệu
          _buildSectionTitle('Quản lý dữ liệu'),
          _buildFAQItem(
            question: 'Làm sao để sửa thông tin bữa ăn?',
            answer: 'Nhấn vào bữa ăn trong danh sách, sau đó chọn "Sửa" để thay đổi tên, calories, hoặc các thông tin khác.',
            icon: Icons.edit,
          ),
          _buildFAQItem(
            question: 'Làm sao để xóa bữa ăn?',
            answer: 'Nhấn vào bữa ăn trong danh sách, sau đó chọn "Xóa". Lưu ý: Hành động này không thể hoàn tác.',
            icon: Icons.delete_outline,
          ),
          _buildFAQItem(
            question: 'Dữ liệu của tôi có được đồng bộ không?',
            answer: 'Có! Tất cả dữ liệu của bạn được tự động đồng bộ lên Firebase. Bạn có thể đăng nhập trên nhiều thiết bị và dữ liệu sẽ được cập nhật.',
            icon: Icons.cloud_sync,
          ),
          
          const SizedBox(height: AppDimensions.marginLarge),
          
          // FAQ Section: Mục tiêu & Thống kê
          _buildSectionTitle('Mục tiêu & Thống kê'),
          _buildFAQItem(
            question: 'Làm sao để thay đổi mục tiêu calories?',
            answer: 'Vào tab "Cá nhân", chọn "Chỉnh sửa hồ sơ". Thay đổi cân nặng mục tiêu, mức độ hoạt động, hoặc loại mục tiêu (giảm/duy trì/tăng cân).',
            icon: Icons.flag,
          ),
          _buildFAQItem(
            question: 'Làm sao để theo dõi cân nặng?',
            answer: 'Vào tab "Cá nhân", chọn "Theo dõi cân nặng". Nhấn nút [+] để thêm cân nặng mới. Bạn sẽ thấy biểu đồ xu hướng cân nặng theo thời gian.',
            icon: Icons.monitor_weight,
          ),
          _buildFAQItem(
            question: 'BMI là gì?',
            answer: 'BMI (Body Mass Index) là chỉ số khối cơ thể, được tính từ cân nặng và chiều cao. BMI giúp đánh giá tình trạng cân nặng của bạn (thiếu cân/bình thường/thừa cân/béo phì).',
            icon: Icons.calculate,
          ),
          
          const SizedBox(height: AppDimensions.marginLarge),
          
          // FAQ Section: Tài khoản
          _buildSectionTitle('Tài khoản'),
          _buildFAQItem(
            question: 'Làm sao để đổi mật khẩu?',
            answer: 'Vào tab "Cá nhân", chọn "Đổi mật khẩu". Nhập mật khẩu hiện tại và mật khẩu mới (tối thiểu 6 ký tự).',
            icon: Icons.lock,
          ),
          _buildFAQItem(
            question: 'Làm sao để đăng xuất?',
            answer: 'Vào tab "Cá nhân", cuộn xuống dưới cùng và nhấn nút "Đăng xuất". Lưu ý: Dữ liệu local sẽ bị xóa, nhưng dữ liệu trên Firebase vẫn được giữ.',
            icon: Icons.logout,
          ),
          _buildFAQItem(
            question: 'Làm sao để xóa tài khoản?',
            answer: 'Vào tab "Cá nhân", chọn "Xóa tài khoản". Bạn sẽ cần xác nhận mật khẩu. Cảnh báo: Tất cả dữ liệu sẽ bị xóa vĩnh viễn và không thể khôi phục!',
            icon: Icons.delete_forever,
          ),
          
          const SizedBox(height: AppDimensions.marginLarge),
          
          // Contact Support
          Container(
            padding: const EdgeInsets.all(AppDimensions.marginLarge),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.support_agent,
                  size: 48,
                  color: AppColors.info,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vẫn cần trợ giúp?',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Liên hệ với chúng tôi qua email:\nsupport@calocam.com',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.marginLarge),
        ],
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.marginMedium,
        left: 4,
      ),
      child: Text(
        title,
        style: AppTextStyles.titleLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Build FAQ item
  Widget _buildFAQItem({
    required String question,
    required String answer,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            question,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 72,
                right: 16,
                bottom: 16,
              ),
              child: Text(
                answer,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

