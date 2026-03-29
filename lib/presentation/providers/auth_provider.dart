import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import 'sync_provider.dart';

/// Authentication Provider
/// 
/// Manages authentication state and provides methods for sign in/sign up/sign out.
/// Uses ChangeNotifier to notify listeners of state changes.
/// 
/// Usage:
/// ```dart
/// // In widget:
/// final authProvider = Provider.of<AuthProvider>(context);
/// 
/// // Sign in:
/// await authProvider.signIn(email, password);
/// 
/// // Check state:
/// if (authProvider.isAuthenticated) {
///   // User is signed in
/// }
/// ```
/// 
/// This provider wraps AuthService and adds UI state management
/// (loading, error handling, etc.)
class AuthProvider extends ChangeNotifier {
  // ==================== SERVICES ====================
  
  final AuthService _authService = AuthService();
  final SyncProvider? _syncProvider;

  // ==================== STATE ====================
  
  /// Current user
  User? _user;

  /// Loading state
  bool _isLoading = false;

  /// Syncing after login state (to show loading in AuthWrapper)
  bool _isSyncingAfterLogin = false;

  /// Error message
  String? _error;

  /// Success message (for showing feedback)
  String? _successMessage;

  // ==================== CONSTRUCTOR ====================
  
  /// Constructor with optional SyncProvider for real-time sync
  AuthProvider({SyncProvider? syncProvider}) : _syncProvider = syncProvider {
    // Initialize: Check current auth state
    _user = _authService.currentUser;

    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      debugPrint('🔐 [AuthProvider] Auth state changed: ${user?.uid ?? "null"}');
      _user = user;
      notifyListeners();
    });
  }

  // ==================== GETTERS ====================
  
  /// Get current user
  User? get user => _user;

  /// Check if user is authenticated
  bool get isAuthenticated => _user != null;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Check if syncing after login (for AuthWrapper)
  bool get isSyncingAfterLogin => _isSyncingAfterLogin;

  /// Get error message
  String? get error => _error;

  /// Get success message
  String? get successMessage => _successMessage;

  /// Get user display name (with fallback)
  String get displayName => _user?.displayName ?? 'User';

  /// Get user email
  String? get email => _user?.email;

  /// Get user photo URL
  String? get photoURL => _user?.photoURL;

  // ==================== PRIVATE HELPERS ====================
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error
  void _setError(String? error) {
    _error = error;
    _successMessage = null; // Clear success message when error occurs
    notifyListeners();
  }

  /// Set success message
  void _setSuccess(String? message) {
    _successMessage = message;
    _error = null; // Clear error when success occurs
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // ==================== EMAIL/PASSWORD AUTH ====================
  
  /// Sign up with email and password
  /// 
  /// Creates a new user account.
  /// 
  /// Parameters:
  /// - [email]: User's email
  /// - [password]: User's password
  /// - [displayName]: User's display name (optional)
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('📝 [AuthProvider] Signing up: $email');

      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Save Firebase UID for data isolation
      if (user != null) {
        await SharedPrefsHelper.saveFirebaseUid(user.uid);
        debugPrint('✅ [AuthProvider] Firebase UID saved: ${user.uid}');
        
        // ✅ FIX: Small delay before clearing loading to ensure AuthWrapper mounts
        await Future.delayed(const Duration(milliseconds: 100));
        _setLoading(false);
        debugPrint('✅ [AuthProvider] Loading cleared after sign up');
        notifyListeners(); // Ensure AuthWrapper gets notification
      }

      _setSuccess('Đăng ký thành công! Chào mừng bạn đến với CaloCam! 🎉');
      debugPrint('✅ [AuthProvider] Sign up successful');
      
      return true;
    } on FirebaseAuthException catch (e) {
      final errorMessage = AuthService.getErrorMessage(e);
      _setError(errorMessage);
      debugPrint('❌ [AuthProvider] Sign up error: $errorMessage');
      return false;
    } catch (e) {
      _setError('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
      debugPrint('❌ [AuthProvider] Unexpected sign up error: $e');
      return false;
    } finally {
      // Only clear loading if not already cleared in success block
      if (_isLoading) {
        _setLoading(false);
        debugPrint('🔄 [AuthProvider] Loading cleared in finally block (sign up)');
      }
    }
  }

  /// Sign in with email and password
  /// 
  /// Authenticates user with their credentials.
  /// 
  /// Parameters:
  /// - [email]: User's registered email
  /// - [password]: User's password
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    bool shouldClearLoading = true; // Track if we should clear loading
    
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('🔑 [AuthProvider] Signing in: $email');

      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      // Save Firebase UID for data isolation
      if (user != null) {
        await SharedPrefsHelper.saveFirebaseUid(user.uid);
        debugPrint('✅ [AuthProvider] Firebase UID saved: ${user.uid}');
        
        // Restore userId from database (if user has completed setup before)
        final db = DatabaseHelper.instance;
        final userMap = await db.getUserByFirebaseUid(user.uid);
        if (userMap != null) {
          // ✅ User found → Has completed setup before
          final userId = userMap['id'] as int;
          await SharedPrefsHelper.saveUserId(userId);
          debugPrint('✅ [AuthProvider] User ID restored from database: $userId');
          
          // ✅ CRITICAL: Keep loading = true, let AuthWrapper handle it
          shouldClearLoading = false;
          
          // Enable real-time sync after successful sign in
          if (_syncProvider != null) {
            _isSyncingAfterLogin = true;
            debugPrint('⏳ [AuthProvider] Starting sync after login...');
            notifyListeners(); // Notify (still loading = true)
            
            await _syncProvider.autoSyncOnLaunch(user.uid);
            debugPrint('✅ [AuthProvider] Real-time sync enabled');
            
            _isSyncingAfterLogin = false;
            debugPrint('✅ [AuthProvider] Sync after login completed');
            
            // ✅ NOW clear loading to allow AuthWrapper to navigate
            _setLoading(false);
            debugPrint('✅ [AuthProvider] Loading cleared, AuthWrapper should navigate');
            notifyListeners(); // Final notify for AuthWrapper
          } else {
            // No sync provider → Clear loading immediately
            _setLoading(false);
            notifyListeners();
          }
        } else {
          // User NOT found → First time, needs setup
          debugPrint('ℹ️ [AuthProvider] User not found in database (first time setup needed)');
          // shouldClearLoading = true (default) → LoginScreen will dismiss
        }
      }

      _setSuccess('Đăng nhập thành công! Chào mừng trở lại! 👋');
      debugPrint('✅ [AuthProvider] Sign in successful');
      
      return true;
    } on FirebaseAuthException catch (e) {
      final errorMessage = AuthService.getErrorMessage(e);
      _setError(errorMessage);
      debugPrint('❌ [AuthProvider] Sign in error: $errorMessage');
      return false;
    } catch (e) {
      _setError('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
      debugPrint('❌ [AuthProvider] Unexpected sign in error: $e');
      return false;
    } finally {
      // Only clear loading if not handled above (errors or first-time setup)
      if (_isLoading && shouldClearLoading) {
        _setLoading(false);
        debugPrint('🔄 [AuthProvider] Loading cleared in finally block');
      }
    }
  }

  // ==================== GOOGLE SIGN-IN ====================
  
  /// Sign in with Google
  /// 
  /// Opens Google Sign-In dialog and authenticates user.
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> signInWithGoogle() async {
    bool shouldClearLoading = true; // Track if we should clear loading
    
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('🔍 [AuthProvider] Starting Google Sign-In');

      final user = await _authService.signInWithGoogle();

      if (user == null) {
        // User cancelled
        debugPrint('⚠️ [AuthProvider] Google Sign-In cancelled');
        _setLoading(false);
        return false;
      }

      // Save Firebase UID for data isolation
      await SharedPrefsHelper.saveFirebaseUid(user.uid);
      debugPrint('✅ [AuthProvider] Firebase UID saved: ${user.uid}');

      // Restore userId from database (if user has completed setup before)
      final db = DatabaseHelper.instance;
      final userMap = await db.getUserByFirebaseUid(user.uid);
      if (userMap != null) {
        // ✅ User found → Has completed setup before
        final userId = userMap['id'] as int;
        await SharedPrefsHelper.saveUserId(userId);
        debugPrint('✅ [AuthProvider] User ID restored from database: $userId');
        
        // ✅ CRITICAL: Keep loading = true, let AuthWrapper handle it
        shouldClearLoading = false;
        
        // Enable real-time sync after successful Google sign in
        if (_syncProvider != null) {
          _isSyncingAfterLogin = true;
          debugPrint('⏳ [AuthProvider] Starting sync after login...');
          notifyListeners(); // Notify (still loading = true)
          
          await _syncProvider.autoSyncOnLaunch(user.uid);
          debugPrint('✅ [AuthProvider] Real-time sync enabled');
          
          _isSyncingAfterLogin = false;
          debugPrint('✅ [AuthProvider] Sync after login completed');
          
          // ✅ NOW clear loading to allow AuthWrapper to navigate
          _setLoading(false);
          debugPrint('✅ [AuthProvider] Loading cleared, AuthWrapper should navigate');
          notifyListeners(); // Final notify for AuthWrapper
        } else {
          // No sync provider → Clear loading immediately
          _setLoading(false);
          notifyListeners();
        }
      } else {
        // User NOT found → First time, needs setup
        debugPrint('ℹ️ [AuthProvider] User not found in database (first time setup needed)');
        // shouldClearLoading = true (default) → LoginScreen will dismiss
      }

      _setSuccess('Đăng nhập bằng Google thành công! 🎉');
      debugPrint('✅ [AuthProvider] Google Sign-In successful');
      
      return true;
    } on FirebaseAuthException catch (e) {
      final errorMessage = AuthService.getErrorMessage(e);
      _setError(errorMessage);
      debugPrint('❌ [AuthProvider] Google Sign-In error: $errorMessage');
      return false;
    } catch (e) {
      _setError('Đăng nhập Google thất bại. Vui lòng thử lại.');
      debugPrint('❌ [AuthProvider] Unexpected Google Sign-In error: $e');
      return false;
    } finally {
      // Only clear loading if not handled above (errors or first-time setup)
      if (_isLoading && shouldClearLoading) {
        _setLoading(false);
        debugPrint('🔄 [AuthProvider] Loading cleared in finally block');
      }
    }
  }

  // ==================== PASSWORD RESET ====================
  
  /// Send password reset email
  /// 
  /// Sends a password reset link to the user's email.
  /// 
  /// Parameters:
  /// - [email]: User's registered email
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('📧 [AuthProvider] Sending password reset to: $email');

      await _authService.sendPasswordResetEmail(email: email);

      _setSuccess('Email reset mật khẩu đã được gửi! Vui lòng kiểm tra hộp thư. 📧');
      debugPrint('✅ [AuthProvider] Password reset email sent');
      
      return true;
    } on FirebaseAuthException catch (e) {
      final errorMessage = AuthService.getErrorMessage(e);
      _setError(errorMessage);
      debugPrint('❌ [AuthProvider] Password reset error: $errorMessage');
      return false;
    } catch (e) {
      _setError('Không thể gửi email reset. Vui lòng thử lại.');
      debugPrint('❌ [AuthProvider] Unexpected password reset error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== SIGN OUT ====================
  
  /// Sign out
  /// 
  /// Signs out the current user and clears all local data.
  /// 
  /// This will:
  /// - Sign out from Firebase
  /// - Clear all local SQLite data (meals, favorites, custom foods)
  /// - Clear all cached state
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> signOut() async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('🚪 [AuthProvider] Signing out');

      // 0. Get Firebase UID before clearing
      final firebaseUid = await SharedPrefsHelper.getFirebaseUid();
      debugPrint('🔑 [AuthProvider] Current Firebase UID: $firebaseUid');

      // 1. Disable real-time sync before sign out
      if (_syncProvider != null) {
        _syncProvider.disableRealTimeSync();
        debugPrint('✅ [AuthProvider] Real-time sync disabled');
      }

      // 2. Sign out from Firebase
      await _authService.signOut();

      // 3. Clear all local data (IMPORTANT: Prevents data leak between users)
      debugPrint('🗑️ [AuthProvider] Clearing local database for UID: $firebaseUid');
      await DatabaseHelper.instance.clearAllData(firebaseUid: firebaseUid);
      debugPrint('✅ [AuthProvider] Local database cleared');

      // 4. Clear SharedPreferences (user profile data)
      debugPrint('🗑️ [AuthProvider] Clearing SharedPreferences...');
      await SharedPrefsHelper.clearAll();
      debugPrint('✅ [AuthProvider] SharedPreferences cleared');

      _setSuccess('Đã đăng xuất thành công! 👋');
      debugPrint('✅ [AuthProvider] Sign out successful');
      
      return true;
    } catch (e) {
      _setError('Không thể đăng xuất. Vui lòng thử lại.');
      debugPrint('❌ [AuthProvider] Sign out error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== USER MANAGEMENT ====================
  
  /// Delete account
  /// 
  /// Permanently deletes the user's account.
  /// User must be recently authenticated.
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('🗑️ [AuthProvider] Deleting account');

      await _authService.deleteAccount();

      _setSuccess('Tài khoản đã được xóa.');
      debugPrint('✅ [AuthProvider] Account deleted');
      
      return true;
    } on FirebaseAuthException catch (e) {
      final errorMessage = AuthService.getErrorMessage(e);
      _setError(errorMessage);
      debugPrint('❌ [AuthProvider] Delete account error: $errorMessage');
      return false;
    } catch (e) {
      _setError('Không thể xóa tài khoản. Vui lòng thử lại.');
      debugPrint('❌ [AuthProvider] Unexpected delete account error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update display name
  /// 
  /// Updates the current user's display name.
  /// 
  /// Parameters:
  /// - [displayName]: New display name
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> updateDisplayName(String displayName) async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('✏️ [AuthProvider] Updating display name to: $displayName');

      await _authService.updateDisplayName(displayName);

      // Reload user to get updated info
      _user = _authService.currentUser;

      _setSuccess('Cập nhật tên hiển thị thành công!');
      debugPrint('✅ [AuthProvider] Display name updated');
      
      return true;
    } catch (e) {
      _setError('Không thể cập nhật tên. Vui lòng thử lại.');
      debugPrint('❌ [AuthProvider] Update display name error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update password
  /// 
  /// Updates the current user's password.
  /// 
  /// Parameters:
  /// - [newPassword]: New password
  /// 
  /// Returns: true if successful, false otherwise
  Future<bool> updatePassword(String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);

      debugPrint('🔒 [AuthProvider] Updating password');

      if (_user == null) {
        _setError('Không tìm thấy người dùng. Vui lòng đăng nhập lại.');
        return false;
      }

      await _user!.updatePassword(newPassword);

      _setSuccess('Cập nhật mật khẩu thành công!');
      debugPrint('✅ [AuthProvider] Password updated');
      
      return true;
    } on FirebaseAuthException catch (e) {
      final errorMessage = AuthService.getErrorMessage(e);
      _setError(errorMessage);
      debugPrint('❌ [AuthProvider] Update password error: $errorMessage');
      return false;
    } catch (e) {
      _setError('Không thể cập nhật mật khẩu. Vui lòng thử lại.');
      debugPrint('❌ [AuthProvider] Unexpected update password error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

