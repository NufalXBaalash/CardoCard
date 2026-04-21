import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_1/firebase_options.dart';
import 'package:test_1/pages/splash_screen_1.dart';
import 'package:test_1/utils/ifLogin.dart';
import 'package:test_1/utils/theme_provider.dart'; // Contains both ThemeProvider and AppTheme classes
import 'package:flutter/foundation.dart';
import 'package:test_1/utils/cache_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:test_1/utils/image_utils.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:test_1/utils/refresh_rate_manager.dart';
import 'package:test_1/utils/notification_service.dart';
import 'package:test_1/utils/serial_service.dart';

void main() async {
  // Ensure Flutter is initialized before accessing native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Serial Service for Arduino Support
  SerialService().init();

  // Set the app to use the highest refresh rate available
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize refresh rate manager for high refresh rate support
  RefreshRateManager.initialize();

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'] ?? '',
  );

  // Initialize notification service
  try {
    final notificationService = NotificationService();
    await notificationService.init().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint("Notification init timeout");
            return;
          },
        );
  } catch (e) {
    debugPrint("Notification service error: $e");
  }

  // Initialize custom cache manager
  try {
    await CacheService.initialize().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint("Cache initialization timeout");
            return;
          },
        );
  } catch (e) {
    debugPrint("Cache service error: $e");
  }

  // Set memory cache size for better performance
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      50 * 1024 * 1024; // 50MB

  // Apply other optimizations based on platform
  if (kReleaseMode) {
    // In release mode, apply additional optimizations
    debugPrint =
        (message, {wrapWidth}) {}; // Disable debug prints in release mode
  }

  // Start the application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          // Initialize language provider on first build
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('ar', ''), // Arabic
            ],
            localizationsDelegates: [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // Apply high refresh rate settings to the entire app
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  devicePixelRatio:
                      1.0, // Force 1:1 pixel ratio for better performance
                ),
                child: Directionality(
                  textDirection: languageProvider.textDirection,
                  child: child!,
                ),
              );
            },
            home: const StartupRouter(),
          );
        },
      ),
    );
  }
}

class StartupRouter extends StatefulWidget {
  const StartupRouter({super.key});

  @override
  State<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<StartupRouter> {
  bool _isLoading = true;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    try {
      // Initialize LanguageProvider if not already done
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (languageProvider.isFirstRun) {
        await languageProvider.initialize();
      }

      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;

      if (mounted) {
        setState(() {
          _isFirstTime = isFirstTime;
          _isLoading = false;
        });
      }

      if (isFirstTime) {
        await prefs.setBool('isFirstTime', false);
      }
    } catch (e) {
      debugPrint("Error in StartupRouter: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      // Updated to use HomeNavigation when not first time
      return _isFirstTime ? const SplashScreen1() : const Iflogin();
    }
  }

  @override
  void dispose() {
    // Clear any caches when app is closed
    ImageUtils.clearCache();
    DefaultCacheManager().emptyCache();
    // Allow the framework to dispose resources
    super.dispose();
  }
}
