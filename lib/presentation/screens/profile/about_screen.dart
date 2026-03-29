import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// About Screen
/// 
/// Displays information about the app:
/// - App name and logo
/// - Version
/// - Description
/// - Features
/// - Copyright
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  /// Load app version
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      debugPrint('Error loading app info: $e');
      if (mounted) {
        setState(() => _appVersion = '1.0.0');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Về ứng dụng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // App Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // App Name
                  Text(
                    'CaloCam',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tagline
                  Text(
                    'Ứng dụng theo dõi calories thông minh',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Version
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Phiên bản $_appVersion',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.marginLarge),
            
            // Description Section
            _buildSection(
              'Giới thiệu',
              'CaloCam là ứng dụng theo dõi calories hiện đại, sử dụng công nghệ AI để nhận diện món ăn từ hình ảnh. Giúp bạn dễ dàng quản lý chế độ ăn uống và đạt được mục tiêu sức khỏe.',
            ),
            
            const SizedBox(height: AppDimensions.marginLarge),
            
            // Features Section
            Container(
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
                  Text(
                    'Tính năng chính',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.marginMedium),
                  _buildFeatureItem(
                    Icons.camera_alt,
                    'Chụp ảnh nhận diện món ăn',
                    'AI tự động nhận diện và tính toán dinh dưỡng',
                  ),
                  _buildFeatureItem(
                    Icons.restaurant_menu,
                    'Quản lý bữa ăn',
                    'Ghi lại và theo dõi các bữa ăn hàng ngày',
                  ),
                  _buildFeatureItem(
                    Icons.favorite,
                    'Món ăn yêu thích',
                    'Lưu và quản lý món ăn thường dùng',
                  ),
                  _buildFeatureItem(
                    Icons.trending_up,
                    'Theo dõi tiến độ',
                    'Xem thống kê và biểu đồ chi tiết',
                  ),
                  _buildFeatureItem(
                    Icons.water_drop,
                    'Nhắc nhở uống nước',
                    'Theo dõi lượng nước uống hàng ngày',
                  ),
                  _buildFeatureItem(
                    Icons.monitor_weight,
                    'Theo dõi cân nặng',
                    'Ghi lại và xem xu hướng cân nặng',
                  ),
                  _buildFeatureItem(
                    Icons.cloud_sync,
                    'Đồng bộ đám mây',
                    'Dữ liệu được lưu trữ an toàn trên Firebase',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.marginLarge),
            
            // Technology Section
            Container(
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
                  Text(
                    'Công nghệ',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.marginMedium),
                  _buildTechItem('Flutter', 'Framework phát triển ứng dụng'),
                  _buildTechItem('Firebase', 'Backend và đồng bộ dữ liệu'),
                  _buildTechItem('GPT-4 Vision', 'AI nhận diện món ăn'),
                  _buildTechItem('SQLite', 'Lưu trữ dữ liệu local'),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.marginLarge),
            
            // Copyright
            Container(
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
                children: [
                  Icon(
                    Icons.copyright,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '© 2025 CaloCam',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All rights reserved',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Phát triển bởi CaloCam Team',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.marginLarge * 2),
          ],
        ),
      ),
    );
  }

  /// Build section with title and description
  Widget _buildSection(String title, String description) {
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
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Build feature item
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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

  /// Build technology item
  Widget _buildTechItem(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: description,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

