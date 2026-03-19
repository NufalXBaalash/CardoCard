import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static late SharedPreferences _prefs;
  static const String _imageKeysKey = 'cached_image_keys';
  static const int _maxCachedImages = 100;

  // Initialize the cache service
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _cleanupOldCache();
    } catch (e) {
      debugPrint('Error initializing cache service: $e');
    }
  }

  // Clean up old cache entries periodically
  static Future<void> _cleanupOldCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFolder = Directory('${cacheDir.path}/image_cache');

      if (await cacheFolder.exists()) {
        final files = await cacheFolder.list().toList();

        // If we have too many files, delete older ones
        if (files.length > _maxCachedImages) {
          // Sort by last modified time
          files.sort((a, b) {
            final aStats = (a as File).statSync();
            final bStats = (b as File).statSync();
            return aStats.modified.compareTo(bStats.modified);
          });

          // Delete oldest files
          final filesToDelete = files.take(files.length - _maxCachedImages);
          for (var file in filesToDelete) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning cache: $e');
    }
  }

  // Save a base64 image to the cache
  static Future<void> cacheBase64Image(String key, String base64Image) async {
    try {
      // Store in shared preferences for small images
      if (base64Image.length < 10000) {
        await _prefs.setString('img_$key', base64Image);

        // Update the list of cached keys
        final cachedKeys = _prefs.getStringList(_imageKeysKey) ?? [];
        if (!cachedKeys.contains(key)) {
          cachedKeys.add(key);
          await _prefs.setStringList(_imageKeysKey, cachedKeys);
        }
      }
      // Store in file system for larger images
      else {
        final cacheDir = await getTemporaryDirectory();
        final cacheFolder = Directory('${cacheDir.path}/image_cache');

        if (!await cacheFolder.exists()) {
          await cacheFolder.create(recursive: true);
        }

        final cacheFile = File('${cacheFolder.path}/$key.bin');
        await cacheFile.writeAsBytes(base64Decode(base64Image));
      }
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
  }

  // Get a base64 image from the cache
  static Future<String?> getCachedBase64Image(String key) async {
    try {
      // Try to get from shared preferences first
      final cachedImage = _prefs.getString('img_$key');
      if (cachedImage != null) {
        return cachedImage;
      }

      // Try to get from file system
      final cacheDir = await getTemporaryDirectory();
      final cacheFile = File('${cacheDir.path}/image_cache/$key.bin');

      if (await cacheFile.exists()) {
        final bytes = await cacheFile.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error retrieving cached image: $e');
    }

    return null;
  }

  // Clear the cache when needed
  static Future<void> clearCache() async {
    try {
      // Clear keys list
      await _prefs.remove(_imageKeysKey);

      // Clear all cached images from shared preferences
      final cachedKeys = _prefs.getStringList(_imageKeysKey) ?? [];
      for (final key in cachedKeys) {
        await _prefs.remove('img_$key');
      }

      // Clear file system cache
      final cacheDir = await getTemporaryDirectory();
      final cacheFolder = Directory('${cacheDir.path}/image_cache');

      if (await cacheFolder.exists()) {
        await cacheFolder.delete(recursive: true);
      }

      // Also clear the default cache manager
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Create a custom cache manager for network images
  static final customCacheManager = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'cardocard_cache'),
      fileService: HttpFileService(),
    ),
  );
}
