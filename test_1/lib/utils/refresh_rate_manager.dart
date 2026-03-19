import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Utility class to manage application refresh rate settings
class RefreshRateManager {
  /// Channel for native platform interaction
  static const MethodChannel _channel =
      MethodChannel('com.cardocard/refresh_rate');

  /// Initialize refresh rate settings for the app
  static Future<void> initialize() async {
    try {
      // Configure system UI for optimal refresh rates
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Set UI overlay style for transparency
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ));

      // Platform-specific optimizations
      if (Platform.isAndroid) {
        await _setAndroidRefreshRate();
      } else if (Platform.isIOS) {
        await _setIOSRefreshRate();
      }
    } catch (e) {
      print('Error setting refresh rate: $e');
    }
  }

  /// Set Android-specific refresh rate
  static Future<void> _setAndroidRefreshRate() async {
    try {
      // Request highest refresh rate on Android
      await _channel.invokeMethod('setHighRefreshRate');
    } catch (e) {
      // Method channel might not be implemented yet
      print('Android refresh rate setting not available: $e');
    }
  }

  /// Set iOS-specific refresh rate
  static Future<void> _setIOSRefreshRate() async {
    try {
      // Request maximum refresh rate on iOS (for 120Hz ProMotion displays)
      await _channel
          .invokeMethod('setPreferredFrameRate', {'frameRate': 120.0});
    } catch (e) {
      // Method channel might not be implemented yet
      print('iOS refresh rate setting not available: $e');
    }
  }
}
