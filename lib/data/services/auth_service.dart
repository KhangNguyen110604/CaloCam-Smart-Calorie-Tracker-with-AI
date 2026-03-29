import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Authentication Service
/// 
/// Handles all Firebase Authentication operations including:
/// - Email/Password sign up and sign in
/// - Google Sign-In
/// - Sign out
/// - Password reset
/// - Auth state monitoring
/// 
/// This service provides a clean abstraction over Firebase Auth,
/// making it easier to test and maintain authentication logic.
class AuthService {
  // ==================== INSTANCES ====================
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ==================== GETTERS ====================
  
  /// Get current user
  /// 
  /// Returns the currently signed-in user, or null if no user is signed in.
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  /// 
  /// Convenience getter to check authentication status
  bool get isSignedIn => currentUser != null;

  /// Stream of auth state changes
  /// 
  /// Listen to this stream to react to authentication state changes.
  /// Useful for implementing auto-navigation when user signs in/out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== EMAIL/PASSWORD AUTH ====================
  
  /// Sign up with email and password
  /// 
  /// Creates a new user account with the provided email and password.
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password (min 6 characters)
  /// - [displayName]: Optional display name for the user
  /// 
  /// Returns:
  /// - [User] object if successful
  /// - null if sign up fails
  /// 
  /// Throws:
  /// - [FirebaseAuthException] with specific error codes:
  ///   - email-already-in-use: The email is already registered
  ///   - invalid-email: The email address is invalid
  ///   - weak-password: The password is too weak
  ///   - operation-not-allowed: Email/password accounts are not enabled
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      debugPrint('🔐 [AuthService] Signing up with email: $email');
      
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      debugPrint('✅ [AuthService] Sign up successful: ${credential.user?.uid}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] Sign up error: ${e.code} - ${e.message}');
      rethrow; // Let the UI handle the error
    } catch (e) {
      debugPrint('❌ [AuthService] Unexpected error during sign up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  /// 
  /// Authenticates a user with their email and password.
  /// 
  /// Parameters:
  /// - [email]: User's registered email
  /// - [password]: User's password
  /// 
  /// Returns:
  /// - [User] object if successful
  /// - null if sign in fails
  /// 
  /// Throws:
  /// - [FirebaseAuthException] with specific error codes:
  ///   - user-not-found: No user found with this email
  ///   - wrong-password: Incorrect password
  ///   - invalid-email: The email address is invalid
  ///   - user-disabled: The user account has been disabled
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 [AuthService] Signing in with email: $email');
      
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ [AuthService] Sign in successful: ${credential.user?.uid}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] Sign in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [AuthService] Unexpected error during sign in: $e');
      rethrow;
    }
  }

  // ==================== GOOGLE SIGN-IN ====================
  
  /// Sign in with Google
  /// 
  /// Opens Google Sign-In flow and authenticates user with Firebase.
  /// 
  /// Flow:
  /// 1. Open Google Sign-In dialog
  /// 2. User selects Google account
  /// 3. Get authentication tokens
  /// 4. Sign in to Firebase with tokens
  /// 
  /// Returns:
  /// - [User] object if successful
  /// - null if user cancels or sign in fails
  /// 
  /// Throws:
  /// - [FirebaseAuthException] if Firebase authentication fails
  /// - [Exception] for other errors (network, etc.)
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔐 [AuthService] Starting Google Sign-In');

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        debugPrint('⚠️ [AuthService] Google Sign-In cancelled by user');
        return null;
      }

      debugPrint('📧 [AuthService] Google account selected: ${googleUser.email}');

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      debugPrint('✅ [AuthService] Google Sign-In successful: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] Google Sign-In error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [AuthService] Unexpected error during Google Sign-In: $e');
      rethrow;
    }
  }

  // ==================== PASSWORD RESET ====================
  
  /// Send password reset email
  /// 
  /// Sends an email to the user with a link to reset their password.
  /// 
  /// Parameters:
  /// - [email]: User's registered email address
  /// 
  /// Throws:
  /// - [FirebaseAuthException] with specific error codes:
  ///   - user-not-found: No user found with this email
  ///   - invalid-email: The email address is invalid
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      debugPrint('📧 [AuthService] Sending password reset email to: $email');
      
      await _auth.sendPasswordResetEmail(email: email);
      
      debugPrint('✅ [AuthService] Password reset email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] Password reset error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [AuthService] Unexpected error sending password reset: $e');
      rethrow;
    }
  }

  // ==================== SIGN OUT ====================
  
  /// Sign out
  /// 
  /// Signs out the current user from both Firebase and Google Sign-In.
  /// Clears all authentication state and tokens.
  /// 
  /// This should be called when user explicitly logs out.
  Future<void> signOut() async {
    try {
      debugPrint('🚪 [AuthService] Signing out');

      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google (if signed in with Google)
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      debugPrint('✅ [AuthService] Sign out successful');
    } catch (e) {
      debugPrint('❌ [AuthService] Error during sign out: $e');
      rethrow;
    }
  }

  // ==================== USER MANAGEMENT ====================
  
  /// Delete user account
  /// 
  /// Permanently deletes the user's Firebase account.
  /// This action cannot be undone.
  /// 
  /// Note: User must have recently signed in for this to work.
  /// If the operation fails with "requires-recent-login" error,
  /// user should sign out and sign in again before deleting.
  /// 
  /// Throws:
  /// - [FirebaseAuthException] with error codes:
  ///   - requires-recent-login: User needs to sign in again
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      debugPrint('🗑️ [AuthService] Deleting account: ${user.uid}');

      await user.delete();

      debugPrint('✅ [AuthService] Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] Delete account error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [AuthService] Unexpected error deleting account: $e');
      rethrow;
    }
  }

  /// Update user display name
  /// 
  /// Updates the display name of the current user.
  /// 
  /// Parameters:
  /// - [displayName]: New display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      debugPrint('✏️ [AuthService] Updating display name to: $displayName');

      await user.updateDisplayName(displayName);
      await user.reload();

      debugPrint('✅ [AuthService] Display name updated');
    } catch (e) {
      debugPrint('❌ [AuthService] Error updating display name: $e');
      rethrow;
    }
  }

  // ==================== ERROR HANDLING ====================
  
  /// Get user-friendly error message from FirebaseAuthException
  /// 
  /// Converts Firebase error codes to readable Vietnamese messages.
  /// 
  /// Parameters:
  /// - [e]: The FirebaseAuthException
  /// 
  /// Returns: User-friendly error message in Vietnamese
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      // Sign up errors
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng sử dụng email khác.';
      case 'invalid-email':
        return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn (ít nhất 6 ký tự).';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt.';

      // Sign in errors
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng. Vui lòng thử lại.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';

      // Network errors
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';

      // Other errors
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại để thực hiện thao tác này.';

      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }
}

