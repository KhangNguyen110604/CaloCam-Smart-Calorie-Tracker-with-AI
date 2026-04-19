import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/user_setup/user_setup_screen.dart';
import 'presentation/screens/main/main_navigation_screen.dart';
import 'presentation/screens/meal_detail/meal_detail_screen.dart';
import 'presentation/screens/add_meal/add_meal_screen.dart';
import 'presentation/screens/progress/weekly_progress_screen.dart';
import 'presentation/screens/history/meal_history_screen.dart';
import 'presentation/providers/meal_provider.dart';
import 'presentation/providers/water_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/food_provider.dart'; // NEW: Food provider for favorites & custom foods
import 'presentation/providers/auth_provider.dart'; // NEW: Auth provider for Firebase Authentication
import 'presentation/providers/sync_provider.dart'; // NEW: Sync provider for Firestore sync

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Environment Variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CaloCountApp());
}

class CaloCountApp extends StatelessWidget {
  const CaloCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Create SyncProvider first (no dependencies)
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        
        // 2. Create providers that depend on SyncProvider
        ChangeNotifierProxyProvider<SyncProvider, AuthProvider>(
          create: (context) => AuthProvider(
            syncProvider: Provider.of<SyncProvider>(context, listen: false),
          ),
          update: (context, syncProvider, previous) => previous ?? AuthProvider(
            syncProvider: syncProvider,
          ),
        ),
        
        ChangeNotifierProxyProvider<SyncProvider, MealProvider>(
          create: (context) => MealProvider(
            syncProvider: Provider.of<SyncProvider>(context, listen: false),
          ),
          update: (context, syncProvider, previous) => previous ?? MealProvider(
            syncProvider: syncProvider,
          ),
        ),
        
        ChangeNotifierProxyProvider<SyncProvider, FoodProvider>(
          create: (context) => FoodProvider(
            syncProvider: Provider.of<SyncProvider>(context, listen: false),
          ),
          update: (context, syncProvider, previous) => previous ?? FoodProvider(
            syncProvider: syncProvider,
          ),
        ),
        
        // 3. Independent providers (no dependencies)
        ChangeNotifierProvider(create: (_) => WaterProvider()..loadTodayIntake()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadThemePreference()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            
            // Theme - ALWAYS Light Mode (Dark mode disabled)
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.light, // ✅ Force light mode always
            
            // Initial Route
            initialRoute: AppRoutes.splash,
        
        // Routes
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.onboarding: (context) => const OnboardingScreen(),
          AppRoutes.userSetup: (context) => const UserSetupScreen(),
          AppRoutes.main: (context) => const MainNavigationScreen(),
        },
        
        // Route Generator for dynamic routes with arguments
        onGenerateRoute: (settings) {
          if (settings.name == '/meal-detail') {
            final mealType = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => MealDetailScreen(mealType: mealType),
            );
          }
          if (settings.name == '/add-meal') {
            final mealType = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => AddMealScreen(mealType: mealType),
            );
          }
          if (settings.name == '/weekly-progress') {
            return MaterialPageRoute(
              builder: (context) => const WeeklyProgressScreen(),
            );
          }
          if (settings.name == '/meal-history') {
            return MaterialPageRoute(
              builder: (context) => const MealHistoryScreen(),
            );
          }
          return null;
        },
          );
        },
      ),
    );
  }
}
