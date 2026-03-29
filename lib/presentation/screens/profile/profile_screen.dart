import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/datasources/local/shared_prefs_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import '../weight/weight_tracking_screen.dart';

/// Profile Screen
/// 
/// Complete profile screen with:
/// - User info card
/// - Stats card (BMI, weight, goal)
/// - Account settings (edit profile, change password, weight tracking)
/// - App settings (dark mode, notifications)
/// - Support (help, about)
/// - Sign out
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await SharedPrefsHelper.getUserId();
      if (userId != null) {
        final profile = await DatabaseHelper.instance.getUser(userId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cá nhân'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // User Info Card
                    _buildUserInfoCard(context, authProvider),
                    
                    const SizedBox(height: 20),
                    
                    // Stats Card (BMI, Weight, Goal)
                    if (_userProfile != null) _buildStatsCard(context),
                    
                    if (_userProfile != null) const SizedBox(height: 20),
                    
                    // Account Section
                    _buildSectionTitle('Tài khoản'),
                    _buildAccountSection(context),
                    
                    const SizedBox(height: 20),
                    
                    // Settings Section
                    _buildSectionTitle('Cài đặt'),
                    _buildSettingsSection(context, themeProvider),
                    
                    const SizedBox(height: 20),
                    
                    // Support Section
                    _buildSectionTitle('Hỗ trợ'),
                    _buildSupportSection(context),
                    
                    const SizedBox(height: 40),
                    
                    // Sign Out Button
                    _buildSignOutButton(context, authProvider),
                    
                    const SizedBox(height: 20),
                    
                    // App Version
                    _buildAppVersion(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build user info card
  Widget _buildUserInfoCard(BuildContext context, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(authProvider.displayName),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.displayName,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.email ?? 'Không có email',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build stats card (BMI, Weight, Goal)
  Widget _buildStatsCard(BuildContext context) {
    final bmi = (_userProfile!['bmi'] as num?)?.toDouble() ?? 0.0;
    final weight = (_userProfile!['weight_kg'] as num?)?.toDouble() ?? 0.0;
    final targetWeight = (_userProfile!['target_weight_kg'] as num?)?.toDouble() ?? 0.0;
    final goalType = _userProfile!['goal_type'] as String? ?? 'maintain';
    final calorieGoal = (_userProfile!['calorie_goal'] as num?)?.toInt() ?? 2000;
    
    final bmiCategory = _getBMICategory(bmi);
    final goalText = _getGoalText(goalType);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Thống kê cá nhân',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.favorite,
                label: 'BMI',
                value: bmi.toStringAsFixed(1),
                subtitle: bmiCategory,
                color: _getBMIColor(bmi),
              ),
              _buildStatItem(
                icon: Icons.monitor_weight,
                label: 'Cân nặng',
                value: '${weight.toStringAsFixed(1)}kg',
                subtitle: 'Hiện tại',
                color: AppColors.secondary,
              ),
              _buildStatItem(
                icon: Icons.flag,
                label: 'Mục tiêu',
                value: '${targetWeight.toStringAsFixed(1)}kg',
                subtitle: goalText,
                color: AppColors.accent,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Calorie Goal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mục tiêu calories: ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$calorieGoal cal/ngày',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _navigateToEditProfile(context),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Chỉnh sửa hồ sơ'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  /// Build section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.marginMedium,
        vertical: 8,
      ),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Build account section
  Widget _buildAccountSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginMedium),
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
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.person_outline,
            title: 'Chỉnh sửa hồ sơ',
            subtitle: 'Cập nhật thông tin cá nhân',
            onTap: () => _navigateToEditProfile(context),
          ),
          // TEMPORARILY HIDDEN: Change Password
          // _buildDivider(),
          // _buildSettingTile(
          //   icon: Icons.lock_outline,
          //   title: 'Đổi mật khẩu',
          //   subtitle: 'Cập nhật mật khẩu bảo mật',
          //   onTap: () => _navigateToChangePassword(context),
          // ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.monitor_weight_outlined,
            title: 'Theo dõi cân nặng',
            subtitle: 'Ghi lại và xem xu hướng cân nặng',
            onTap: () => _navigateToWeightTracking(context),
          ),
        ],
      ),
    );
  }

  /// Build settings section
  Widget _buildSettingsSection(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginMedium),
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
      child: Column(
        children: [
          // TEMPORARILY HIDDEN: Dark Mode Toggle
          // _buildSwitchTile(
          //   icon: Icons.dark_mode_outlined,
          //   title: 'Chế độ tối',
          //   subtitle: 'Giao diện tối dễ nhìn hơn ban đêm',
          //   value: themeProvider.isDarkMode,
          //   onChanged: (value) {
          //     themeProvider.toggleTheme();
          //   },
          // ),
          // _buildDivider(),
          _buildSettingTile(
            icon: Icons.delete_outline,
            title: 'Xóa tài khoản',
            subtitle: 'Xóa vĩnh viễn tài khoản và dữ liệu',
            onTap: () => _showDeleteAccountDialog(context),
            textColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  /// Build support section
  Widget _buildSupportSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginMedium),
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
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.help_outline,
            title: 'Trợ giúp',
            subtitle: 'Câu hỏi thường gặp',
            onTap: () => _navigateToHelp(context),
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'Về ứng dụng',
            subtitle: 'Thông tin và phiên bản',
            onTap: () => _navigateToAbout(context),
          ),
        ],
      ),
    );
  }

  /// Build setting tile
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Icon(icon, color: textColor ?? AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textHint,
      ),
      onTap: onTap,
    );
  }


  /// Build divider
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
    );
  }

  /// Build sign out button
  Widget _buildSignOutButton(BuildContext context, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginMedium),
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: authProvider.isLoading ? null : () => _handleSignOut(context, authProvider),
        icon: authProvider.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.logout, color: Colors.white),
        label: Text(
          authProvider.isLoading ? 'Đang đăng xuất...' : 'Đăng xuất',
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Build app version
  Widget _buildAppVersion() {
    return Column(
      children: [
        Text(
          'CaloCam',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version 1.0.0',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  // ==================== NAVIGATION ====================

  /// Navigate to edit profile
  Future<void> _navigateToEditProfile(BuildContext context) async {
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userProfile: _userProfile!),
      ),
    );

    // Reload profile if edited
    if (result == true) {
      _loadUserProfile();
    }
  }


  /// Navigate to weight tracking
  void _navigateToWeightTracking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeightTrackingScreen()),
    );
  }

  /// Navigate to help
  void _navigateToHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
  }

  /// Navigate to about
  void _navigateToAbout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  // ==================== ACTIONS ====================

  /// Handle sign out
  Future<void> _handleSignOut(BuildContext context, AuthProvider authProvider) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?\n\n'
          '⚠️ Dữ liệu cục bộ sẽ bị xóa, nhưng dữ liệu trên đám mây vẫn được giữ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Sign out
      final success = await authProvider.signOut();

      if (success && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.successMessage ?? 'Đã đăng xuất thành công!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate to LoginScreen (clear all previous routes)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      } else if (context.mounted && authProvider.error != null) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show delete account dialog
  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Step 1: Show warning dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Xóa tài khoản'),
          ],
        ),
        content: const Text(
          'CẢNH BÁO: Hành động này KHÔNG THỂ HOÀN TÁC!\n\n'
          'Tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn:\n'
          '• Lịch sử bữa ăn\n'
          '• Món ăn tùy chỉnh\n'
          '• Thống kê và tiến độ\n'
          '• Lịch sử cân nặng\n'
          '• Tài khoản Firebase\n\n'
          'Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Step 2: Delete account
      final success = await authProvider.deleteAccount();
      
      if (success && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tài khoản đã được xóa'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to LoginScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (context.mounted && authProvider.error != null) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ==================== HELPERS ====================

  /// Get initials from name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /// Get BMI category
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  /// Get BMI color
  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return AppColors.warning;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }

  /// Get goal text
  String _getGoalText(String goalType) {
    switch (goalType) {
      case 'lose':
        return 'Giảm cân';
      case 'gain':
        return 'Tăng cân';
      case 'maintain':
      default:
        return 'Duy trì';
    }
  }
}

