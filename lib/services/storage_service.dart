// lib/services/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // For web environments, we'll store the blob URLs directly
  // This avoids Firebase Storage issues in development
  Future<String> uploadImage(File file, String folderPath) async {
    try {
      // For web in development mode, just return the blob URL directly
      if (kIsWeb && kDebugMode) {
        print("Web development mode: Using blob URL directly instead of Firebase Storage");
        return file.path; // On web, this is already a blob URL
      }

      // For production or mobile, use Firebase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}';
      final String fullPath = '$folderPath/$fileName';
      final Reference ref = _storage.ref().child(fullPath);

      UploadTask uploadTask;
      if (kIsWeb) {
        // For web, we need to get bytes
        final Uint8List bytes = await file.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        // For mobile
        uploadTask = ref.putFile(file);
      }

      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('StorageService error: $e');

      // In debug mode, use placeholders
      if (kDebugMode) {
        if (kIsWeb) {
          // If this is web and we have a blob URL, use that
          if (file.path.startsWith('blob:')) {
            print('Using blob URL as fallback: ${file.path}');
            return file.path;
          }
        }
        // Fallback to placeholder
        return 'https://via.placeholder.com/400x300?text=Image';
      }

      // In production, rethrow
      throw Exception('Failed to upload image: $e');
    }
  }

  // Helper methods for specific upload types
  Future<String> uploadProfilePicture(String userId, File image) async {
    return uploadImage(image, 'profile_pictures/$userId');
  }

  Future<String> uploadIdentityDocument(String userId, File document) async {
    return uploadImage(document, 'identity_documents/$userId');
  }

  Future<String> uploadPropertyImage(String propertyId, File image) async {
    return uploadImage(image, 'property_images/$propertyId');
  }
}