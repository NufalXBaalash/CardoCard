import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

class ImageUtils {
  // Cache for decoded images to avoid repeated decoding of the same base64 string
  static final Map<String, Uint8List> _imageCache = {};
  static const int _maxCacheSize =
      10; // Maximum number of images to keep in memory

  // Convert base64 string to ImageProvider for use with CircleAvatar or BoxDecoration
  static ImageProvider imageProviderFromBase64String(String base64String) {
    try {
      final imageData = base64Decode(base64String);
      return MemoryImage(imageData);
    } catch (e) {
      debugPrint('Error creating ImageProvider from base64: $e');
      return const AssetImage("lib/images/default_profile.jpg");
    }
  }

  // Convert base64 string to Image widget with caching
  static Widget imageFromBase64String(
    String base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    try {
      // Use cached data if available
      Uint8List imageData;
      if (_imageCache.containsKey(base64String)) {
        imageData = _imageCache[base64String]!;
      } else {
        // Decode and cache
        imageData = base64Decode(base64String);

        // Only cache if not too large (1MB max)
        if (imageData.length < 1024 * 1024) {
          // Manage cache size
          if (_imageCache.length >= _maxCacheSize) {
            // Remove oldest entry
            final firstKey = _imageCache.keys.first;
            _imageCache.remove(firstKey);
          }
          _imageCache[base64String] = imageData;
        }
      }

      // Use memory-efficient image constructor with cacheWidth/cacheHeight for downsampling
      return Image.memory(
        imageData,
        width: width,
        height: height,
        fit: fit,
        // Add cacheWidth and cacheHeight for more efficient memory usage
        cacheWidth: width != null ? (width * 1.5).toInt() : null,
        cacheHeight: height != null ? (height * 1.5).toInt() : null,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading base64 image: $error');
          return errorWidget ?? _defaultErrorWidget(width, height);
        },
      );
    } catch (e) {
      debugPrint('Exception in imageFromBase64String: $e');
      return errorWidget ?? _defaultErrorWidget(width, height);
    }
  }

  // Pre-decode base64 images in a background isolate
  static Future<Uint8List?> decodeBase64ImageAsync(String base64String) async {
    try {
      // Use compute to move decoding to a separate isolate
      return await compute(_decodeBase64, base64String);
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return null;
    }
  }

  // Helper function for isolate
  static Uint8List _decodeBase64(String base64String) {
    return base64Decode(base64String);
  }

  // Default error widget when image fails to load
  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[600],
        size: (width != null && height != null) ? (width + height) / 6 : 40,
      ),
    );
  }

  // Check if a string is a valid base64 image
  static bool isValidBase64Image(String str) {
    if (str.isEmpty) return false;

    try {
      final decodedBytes = base64Decode(str);
      // Check minimum viable length for an image
      return decodedBytes.length > 100;
    } catch (e) {
      return false;
    }
  }

  // Clear the image cache when no longer needed
  static void clearCache() {
    _imageCache.clear();
  }
}
