import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LanguageProvider with ChangeNotifier {
  // Singleton instance
  static final LanguageProvider _instance = LanguageProvider._internal();
  factory LanguageProvider() => _instance;
  LanguageProvider._internal();

  // Constants
  static const String _languagePreferenceKey = 'selected_language';
  static const String _autoDetectPreferenceKey = 'auto_detect_language';
  static const String _cachedCountryCodeKey = 'cached_country_code';
  static const String _lastCountryCheckTimeKey = 'last_country_check_time';

  // Available languages
  static const String ENGLISH = 'en';
  static const String ARABIC = 'ar';

  // Language RTL map
  static final Map<String, bool> _isRTLMap = {
    ENGLISH: false,
    ARABIC: true,
  };

  // Countries where Arabic is commonly spoken
  static final List<String> _arabicRegions = [
    'SA', // Saudi Arabia
    'AE', // UAE
    'QA', // Qatar
    'KW', // Kuwait
    'BH', // Bahrain
    'OM', // Oman
    'JO', // Jordan
    'LB', // Lebanon
    'SY', // Syria
    'IQ', // Iraq
    'PS', // Palestine
    'YE', // Yemen
    'EG', // Egypt
    'SD', // Sudan
    'LY', // Libya
    'TN', // Tunisia
    'DZ', // Algeria
    'MA', // Morocco
    'MR', // Mauritania
    'KM', // Comoros
    'DJ', // Djibouti
    'SO', // Somalia
  ];

  // State variables
  String _currentLanguage = ENGLISH;
  bool _autoDetectLanguage = true;
  bool _isFirstRun = true;
  String? _cachedCountryCode;
  DateTime? _lastCountryCheckTime;
  bool _isLocationDetectionInProgress = false;
  bool _isFirstTimeEverRun =
      false; // Track if this is the first time the app has ever run

  // Getters
  String get currentLanguage => _currentLanguage;
  bool get isAutoDetect => _autoDetectLanguage;
  bool get isRTL => _isRTLMap[_currentLanguage] ?? false;
  Locale get locale => Locale(_currentLanguage);
  bool get isArabic => _currentLanguage == ARABIC;
  bool get isFirstRun => _isFirstRun;

  // Initialize the language provider
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if this is the first time the app has ever run
      _isFirstTimeEverRun = !prefs.containsKey(_languagePreferenceKey) &&
          !prefs.containsKey(_autoDetectPreferenceKey);

      // Load saved preferences
      _autoDetectLanguage = prefs.getBool(_autoDetectPreferenceKey) ?? true;

      // Load cached country code
      final cachedCountryCode = prefs.getString(_cachedCountryCodeKey);
      if (cachedCountryCode != null) {
        _cachedCountryCode = cachedCountryCode;
      }

      // Load last check time
      final lastCheckTimeMillis = prefs.getInt(_lastCountryCheckTimeKey);
      if (lastCheckTimeMillis != null) {
        _lastCountryCheckTime =
            DateTime.fromMillisecondsSinceEpoch(lastCheckTimeMillis);
      }

      if (_isFirstTimeEverRun) {
        // On first run ever, always detect from device without saving preference
        _currentLanguage = await _detectLanguageFromDevice();
        // Don't save the preference yet - allow user to change it manually later
      } else if (_autoDetectLanguage) {
        // Auto-detect language based on region (using cached preferences)
        final detectedLanguage = await _detectLanguage();
        _currentLanguage = detectedLanguage;

        // If we're using the device's location detection, start it in the background
        // to refresh the cached value if needed (won't block initialization)
        _checkLocationInBackground();
      } else {
        // Use manually selected language
        _currentLanguage = prefs.getString(_languagePreferenceKey) ?? ENGLISH;
      }

      _isFirstRun = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing language provider: $e');
      // Default to English in case of error
      _currentLanguage = ENGLISH;
      _isFirstRun = false;
      notifyListeners();
    }
  }

  // Run location check in background to update cache without blocking UI
  Future<void> _checkLocationInBackground() async {
    if (!_isLocationDetectionInProgress) {
      _isLocationDetectionInProgress = true;
      try {
        // Wait for 2 seconds to not immediately trigger location services
        await Future.delayed(const Duration(seconds: 2));
        await _getCountryFromLocation(forceCheck: true);
      } finally {
        _isLocationDetectionInProgress = false;
      }
    }
  }

  // Detect language based on system locale and region
  Future<String> _detectLanguage() async {
    try {
      // Method 1: Try to detect from system locale first (fastest)
      final systemLocales = ui.PlatformDispatcher.instance.locales;
      for (final locale in systemLocales) {
        if (locale.languageCode == ARABIC) {
          return ARABIC;
        }
      }

      // Method 2: Check country code from device locale settings
      for (final locale in systemLocales) {
        if (locale.countryCode != null &&
            _arabicRegions.contains(locale.countryCode!.toUpperCase())) {
          return ARABIC;
        }
      }

      // Method 3: Check if device language suggests Arabic script
      final primaryLocale = ui.PlatformDispatcher.instance.locale;
      if (_isArabicScript(primaryLocale.languageCode)) {
        return ARABIC;
      }

      // Method 4: Check for cached country code from previous location detection
      if (_cachedCountryCode != null &&
          _arabicRegions.contains(_cachedCountryCode!.toUpperCase())) {
        return ARABIC;
      }

      // Method 5: Try immediate location check if we have permissions already
      // Note: This won't prompt for permissions during startup to avoid disrupting UX
      final locationPermission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 2),
        onTimeout: () => LocationPermission.denied,
      );
      if (locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always) {
        final countryCode = await _getCountryFromLocation(forceCheck: false);
        if (countryCode != null && _arabicRegions.contains(countryCode)) {
          return ARABIC;
        }
      }
    } catch (e) {
      debugPrint('Error detecting language: $e');
    }

    // Default to English
    return ENGLISH;
  }

  // Get country code using location services
  Future<String?> _getCountryFromLocation({bool forceCheck = false}) async {
    try {
      final now = DateTime.now();

      // Check if we have a cached country code that's recent (within 24 hours)
      if (!forceCheck &&
          _cachedCountryCode != null &&
          _lastCountryCheckTime != null) {
        final difference = now.difference(_lastCountryCheckTime!);
        if (difference.inHours < 24) {
          return _cachedCountryCode;
        }
      }

      // Check location permissions without showing a prompt
      LocationPermission permission = await Geolocator.checkPermission();

      // If forcing a check and we don't have permission, request it
      if (forceCheck && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Return null if we don't have permission
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        // Get current position with a timeout
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );

        // Get place information from coordinates
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final countryCode = placemarks.first.isoCountryCode;
          if (countryCode != null && countryCode.isNotEmpty) {
            // Cache the result
            _cachedCountryCode = countryCode.toUpperCase();
            _lastCountryCheckTime = now;

            // Save to preferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_cachedCountryCodeKey, _cachedCountryCode!);
            await prefs.setInt(
                _lastCountryCheckTimeKey, now.millisecondsSinceEpoch);

            // If auto-detect is enabled, and the user is in an Arabic region,
            // update the language immediately
            if (_autoDetectLanguage &&
                _arabicRegions.contains(_cachedCountryCode!) &&
                _currentLanguage != ARABIC) {
              _currentLanguage = ARABIC;
              notifyListeners();
            } else if (_autoDetectLanguage &&
                !_arabicRegions.contains(_cachedCountryCode!) &&
                _currentLanguage != ENGLISH) {
              _currentLanguage = ENGLISH;
              notifyListeners();
            }

            return _cachedCountryCode;
          }
        }
      } catch (e) {
        debugPrint('Error getting location or geocoding: $e');
      }
    } catch (e) {
      debugPrint('Error in _getCountryFromLocation: $e');
    }

    return null;
  }

  // Helper method to check if a language code is associated with Arabic script
  bool _isArabicScript(String languageCode) {
    // Languages that use Arabic script
    final arabicScriptLanguages = [
      'ar', // Arabic
      'fa', // Persian
      'ur', // Urdu
      'ps', // Pashto
      'sd', // Sindhi
      'ckb', // Central Kurdish
      'ug', // Uyghur
    ];

    return arabicScriptLanguages.contains(languageCode.toLowerCase());
  }

  // Toggle auto-detection
  Future<void> setAutoDetect(bool value) async {
    if (_autoDetectLanguage == value) return;

    _autoDetectLanguage = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDetectPreferenceKey, value);

    if (value) {
      // If enabling auto-detect, update the language immediately
      final detectedLanguage = await _detectLanguage();
      await setLanguage(detectedLanguage, savePreference: false);

      // Trigger a background location check to refresh the cached country
      _checkLocationInBackground();
    }

    notifyListeners();
  }

  // Set language manually
  Future<void> setLanguage(String languageCode,
      {bool savePreference = true}) async {
    if (!_isRTLMap.containsKey(languageCode)) {
      throw ArgumentError('Unsupported language code: $languageCode');
    }

    if (_currentLanguage == languageCode) return;

    _currentLanguage = languageCode;

    if (savePreference) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languagePreferenceKey, languageCode);

      // When manually setting language, disable auto-detection
      if (_autoDetectLanguage) {
        _autoDetectLanguage = false;
        await prefs.setBool(_autoDetectPreferenceKey, false);
      }

      // Mark that the app is no longer in first-time-ever mode
      if (_isFirstTimeEverRun) {
        _isFirstTimeEverRun = false;
      }
    }

    notifyListeners();
  }

  // Get the text direction based on current language
  TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;

  // Detect language directly from device locale without location checks
  Future<String> _detectLanguageFromDevice() async {
    try {
      // Get primary system locale
      final primaryLocale = ui.PlatformDispatcher.instance.locale;

      // Simply check if the primary locale is Arabic
      if (primaryLocale.languageCode == ARABIC) {
        return ARABIC;
      }

      // Check if the language uses Arabic script
      if (_isArabicScript(primaryLocale.languageCode)) {
        return ARABIC;
      }

      // Don't check for country or location, just use the language directly
    } catch (e) {
      debugPrint('Error detecting device language: $e');
    }

    // Default to English if no Arabic locale is found
    return ENGLISH;
  }
}
