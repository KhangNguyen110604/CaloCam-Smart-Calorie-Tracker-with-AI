import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main/main_navigation_screen.dart';
import '../user_setup/user_setup_screen.dart';
import 'login_screen.dart';
import '../../../data/datasources/local/shared_prefs_helper.dart';
import '../../../data/datasources/local/database_helper.dart';

/// Auth Wrapper
/// 
/// Determines which screen to show based on authentication state:
/// - If user is NOT signed in → Show LoginScreen
/// - If user is signed in BUT hasn't completed setup → Show UserSetupScreen
/// - If user is signed in AND has completed setup → Show MainNavigationScreen
/// 
/// This widget listens to AuthProvider and automatically updates
/// when auth state changes (sign in/sign out).
/// 
/// Usage:
/// Replace SplashScreen → MainNavigationScreen navigation with:
/// SplashScreen → AuthWrapper
/// 
/// The AuthWrapper will then route to the appropriate screen.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingSetup = false;
  bool _hasCompletedSetup = false;
  String? _lastCheckedFirebaseUid; // Track which user we last checked
  bool _needsForceCheck = false; // Force check after sign out

  /// Check if user has completed setup
  /// 
  /// Setup is considered complete when user has BMI data in database
  Future<void> _checkUserSetupStatus(String firebaseUid) async {
    if (_isCheckingSetup) {
      debugPrint('⚠️ [AuthWrapper] Already checking setup, skipping...');
      return;
    }
    
    debugPrint('🔍 [AuthWrapper] Checking setup for: $firebaseUid');
    
    setState(() {
      _isCheckingSetup = true;
    });
    
    try {
      // Small delay to ensure database is ready after sync
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check if user has BMI data in database
      final db = DatabaseHelper.instance;
      final userMap = await db.getUserByFirebaseUid(firebaseUid);
      
      if (userMap != null) {
        // User exists → Has completed setup
        final dbUserId = userMap['id'] as int;
        
        // Restore userId to SharedPreferences if needed
        final currentUserId = await SharedPrefsHelper.getUserId();
        if (currentUserId == null) {
          await SharedPrefsHelper.saveUserId(dbUserId);
          debugPrint('✅ [AuthWrapper] Restored userId: $dbUserId');
        }
        
        debugPrint('✅ [AuthWrapper] User has completed setup → MainNavigationScreen');
        
        if (mounted) {
          setState(() {
            _hasCompletedSetup = true;
            _isCheckingSetup = false;
            _lastCheckedFirebaseUid = firebaseUid;
            _needsForceCheck = false; // ✅ Clear force check flag
          });
        }
      } else {
        // User NOT in database → Needs setup
        debugPrint('ℹ️ [AuthWrapper] User needs setup → UserSetupScreen');
        
        if (mounted) {
          setState(() {
            _hasCompletedSetup = false;
            _isCheckingSetup = false;
            _lastCheckedFirebaseUid = firebaseUid;
            _needsForceCheck = false; // ✅ Clear force check flag
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [AuthWrapper] Error checking setup: $e');
      if (mounted) {
        setState(() {
          _hasCompletedSetup = false;
          _isCheckingSetup = false;
          _needsForceCheck = false; // ✅ Clear force check flag even on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isSyncing = authProvider.isSyncingAfterLogin;
        final currentFirebaseUid = authProvider.user?.uid;
        final isLoading = authProvider.isLoading;
        
        debugPrint('🔄 [AuthWrapper] build: auth=$isAuthenticated, loading=$isLoading, sync=$isSyncing, uid=$currentFirebaseUid, lastChecked=$_lastCheckedFirebaseUid, forceCheck=$_needsForceCheck');
        
        // ==================== NOT AUTHENTICATED ====================
        if (!isAuthenticated) {
          // ✅ FIX: Reset state when signed out (only if there was a previous user)
          if (_hasCompletedSetup || _lastCheckedFirebaseUid != null) {
            debugPrint('🔄 [AuthWrapper] User signed out, resetting state immediately');
            // Reset immediately (no need for postFrameCallback)
            _hasCompletedSetup = false;
            _isCheckingSetup = false;
            _lastCheckedFirebaseUid = null;
            _needsForceCheck = true; // ✅ Force check on next login
            debugPrint('✅ [AuthWrapper] State reset completed, forceCheck=true');
          }
          
          debugPrint('🔐 [AuthWrapper] Not authenticated → LoginScreen');
          return const LoginScreen();
        }
        
        // ==================== AUTHENTICATED ====================
        
        // ✅ Show loading while AuthProvider is loading or syncing
        if (isLoading || isSyncing) {
          debugPrint('⏳ [AuthWrapper] Loading/Syncing... (loading=$isLoading, sync=$isSyncing)');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang đồng bộ dữ liệu...'),
                ],
              ),
            ),
          );
        }
        
        // ✅ KEY FIX: After sync done, check if we need to check setup
        // Check setup if:
        // 1. We haven't checked this user before (_lastCheckedFirebaseUid != currentFirebaseUid)
        // 2. OR we need to force check (after sign out in same session)
        // 3. Not currently checking
        // 4. Sync is done (!isSyncing)
        final needsSetupCheck = currentFirebaseUid != null && 
                               (_lastCheckedFirebaseUid != currentFirebaseUid || _needsForceCheck) &&
                               !_isCheckingSetup;
        
        if (needsSetupCheck) {
          debugPrint('🔍 [AuthWrapper] Need to check setup (UID changed: ${_lastCheckedFirebaseUid != currentFirebaseUid}, Force: $_needsForceCheck)');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isCheckingSetup) {
              _checkUserSetupStatus(currentFirebaseUid);
            }
          });
          
          // Show loading while checking
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang kiểm tra...'),
                ],
              ),
            ),
          );
        }
        
        // Show loading while checking setup
        if (_isCheckingSetup) {
          debugPrint('⏳ [AuthWrapper] Checking setup...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // ==================== ROUTE TO APPROPRIATE SCREEN ====================
        
        if (_hasCompletedSetup) {
          debugPrint('✅ [AuthWrapper] Setup completed → MainNavigationScreen');
          return const MainNavigationScreen();
        } else {
          debugPrint('ℹ️ [AuthWrapper] Setup needed → UserSetupScreen');
          return const UserSetupScreen();
        }
      },
    );
  }
}

