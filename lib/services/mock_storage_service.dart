// lib/services/mock_storage_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';


class MockStorageService {
  // In-memory storage of image paths
  static final Map<String, String> _imageCache = {};

  Future<String> uploadImage(File file, String folderPath) async {
    try {
      // Generate a unique ID for this image
      final String imageId = const Uuid().v4();
      final String cacheKey = '$folderPath/$imageId';

      if (kIsWeb) {
        // On web, we just keep the original path which is already a blob URL
        _imageCache[cacheKey] = file.path;
        return file.path;
      } else {
        // On mobile, we store the file path
        _imageCache[cacheKey] = file.path;
        return file.path;
      }
    } catch (e) {
      print('MockStorageService error: $e');
      return 'https://via.placeholder.com/400x300?text=Image+Placeholder';
    }
  }

  /// Upload a profile picture
  Future<String> uploadProfilePicture(String userId, File image) async {
    return uploadImage(image, 'profile_pictures/$userId');
  }

  /// Upload an identity document
  Future<String> uploadIdentityDocument(String userId, File document) async {
    return uploadImage(document, 'identity_documents/$userId');
  }

  /// Upload a property image
  Future<String> uploadPropertyImage(String propertyId, File image) async {
    return uploadImage(image, 'property_images/$propertyId');
  }

  /// Get an image by its cache key
  String? getImagePath(String cacheKey) {
    return _imageCache[cacheKey];
  }

  /// Check if an image exists in the cache
  bool hasImage(String cacheKey) {
    return _imageCache.containsKey(cacheKey);
  }

  /// Delete an image
  Future<void> deleteImage(String url) async {
    // Find and remove the image from our cache
    _imageCache.removeWhere((key, value) => value == url);
  }
}