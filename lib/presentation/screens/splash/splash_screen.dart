import 'package:flutter/material.dart';
import '../../../data/datasources/local/shared_prefs_helper.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/auth_wrapper.dart'; // NEW: Route to AuthWrapper for auth check

/// Splash Screen - Instant navigation (no Flutter animation)
/// Native splash will show during app startup, then immediately route to next screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate immediately after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    // Check if first time (onboarding shown or not)
    final isFirstTime = await SharedPrefsHelper.isFirstTime();

    if (!mounted) return;

    // Navigate immediately (no delay)
    if (isFirstTime) {
      // First time -> Show Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      // Not first time -> Go to AuthWrapper (will handle auth state)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container - navigation happens in initState
    // Native splash will show until navigation completes
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(), // Empty - native splash handles display
    );
  }
}

