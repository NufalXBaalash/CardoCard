// Add this ThemeProvider class (should be in a separate file like theme_provider.dart)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Light theme colors
  static const Color primaryLight = Color(0xFF00A2E1); // New primary color
  static const Color secondaryLight =
      Color(0xFF66C7EF); // Lighter shade of primary
  static const Color backgroundLight = Colors.white;
  static const Color surfaceLight = Colors.white;
  static const Color errorLight = Color(0xFFB00020);
  static const Color onPrimaryLight = Colors.white;
  static const Color onSecondaryLight = Colors.black;
  static const Color onBackgroundLight = Colors.black;
  static const Color onSurfaceLight = Colors.black;
  static const Color onErrorLight = Colors.white;
  static const Color cardColorLight = Colors.white;
  static const Color shadowColorLight = Color(0x1A000000);
  static const Color cardShadowLight = Color(0x26000000);

  // CardoCard specific colors (shared between themes)
  static const Color cardoBlue = Color(0xFF00A2E1); // Updated to match primary
  static const Color cardoCardBlue =
      Color(0xFF33B5E5); // Adjusted to match new primary
  static const Color cardoDarkBlue =
      Color(0xFF0088C3); // Darker shade of primary
  static const Color cardoLightBlue =
      Color(0xFF66C7EF); // Lighter shade of primary
  static const Color cardoPaleBlue =
      Color(0xFFB3E5F7); // Very light shade of primary
  static const Color cardoCenterBlue = Color(0xFF00A2E1); // Same as primary
  static const Color cardoLightGrey = Color(0xffF1F1F1);

  // Dark theme colors
  static const Color primaryDark =
      Color(0xFF00A2E1); // Updated to match light theme primary
  static const Color secondaryDark =
      Color(0xFF66C7EF); // Lighter shade of primary
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color errorDark = Color(0xFFCF6679);
  static const Color onPrimaryDark = Colors.white;
  static const Color onSecondaryDark = Colors.black;
  static const Color onBackgroundDark = Colors.white;
  static const Color onSurfaceDark = Colors.white;
  static const Color onErrorDark = Colors.black;
  static const Color cardColorDark = Color(0xFF2C2C2C);
  static const Color shadowColorDark = Color(0x52000000);
  static const Color cardShadowDark = Color(0x26FFFFFF);

  // Get light theme
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Cairo', // Set Cairo as the default font family
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        background: backgroundLight,
        error: errorLight,
        onPrimary: onPrimaryLight,
        onSecondary: onSecondaryLight,
        onSurface: onSurfaceLight,
        onBackground: onBackgroundLight,
        onError: onErrorLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardColorLight,
      shadowColor: shadowColorLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: onSurfaceLight,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: onPrimaryLight,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryLight;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryLight.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primaryLight,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
      cardTheme: CardTheme(
        color: cardColorLight,
        elevation: 2,
        shadowColor: cardShadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: onSurfaceLight, fontFamily: 'Cairo'),
        bodyMedium: TextStyle(color: onSurfaceLight, fontFamily: 'Cairo'),
        bodySmall: TextStyle(color: onSurfaceLight, fontFamily: 'Cairo'),
        titleLarge: TextStyle(color: onSurfaceLight, fontFamily: 'Cairo'),
        titleMedium: TextStyle(color: onSurfaceLight, fontFamily: 'Cairo'),
        titleSmall: TextStyle(color: onSurfaceLight, fontFamily: 'Cairo'),
      ),
    );
  }

  // Get dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Cairo', // Set Cairo as the default font family
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        background: backgroundDark,
        error: errorDark,
        onPrimary: onPrimaryDark,
        onSecondary: onSecondaryDark,
        onSurface: onSurfaceDark,
        onBackground: onBackgroundDark,
        onError: onErrorDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardColorDark,
      shadowColor: shadowColorDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: onSurfaceDark,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: onPrimaryDark,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryDark;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryDark.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primaryDark,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3E3E3E),
        thickness: 1,
      ),
      cardTheme: CardTheme(
        color: cardColorDark,
        elevation: 2,
        shadowColor: cardShadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: onSurfaceDark, fontFamily: 'Cairo'),
        bodyMedium: TextStyle(color: onSurfaceDark, fontFamily: 'Cairo'),
        bodySmall: TextStyle(color: onSurfaceDark, fontFamily: 'Cairo'),
        titleLarge: TextStyle(color: onSurfaceDark, fontFamily: 'Cairo'),
        titleMedium: TextStyle(color: onSurfaceDark, fontFamily: 'Cairo'),
        titleSmall: TextStyle(color: onSurfaceDark, fontFamily: 'Cairo'),
      ),
    );
  }
}

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkMode);

    notifyListeners();
  }

  // Get the current theme
  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme() : AppTheme.lightTheme();
}
