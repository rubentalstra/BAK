import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient supabase;

  ImageUploadService(this.supabase);

  // Constants
  static const int maxFileSizeInMB = 2;
  static const int maxFileSizeInBytes = maxFileSizeInMB * 1024 * 1024;

  // Upload profile image to 'user-profile-images' bucket
  Future<String?> uploadProfileImage(
      File imageFile, String userId, String? existingFilePath) async {
    try {
      if (imageFile.lengthSync() > maxFileSizeInBytes) {
        throw Exception('File size exceeds the 2MB limit');
      }

      // Delete the existing profile image if it exists
      if (existingFilePath != null && existingFilePath.isNotEmpty) {
        await supabase.storage
            .from('user-profile-images')
            .remove([existingFilePath]);
      }

      // Generate new file path for the new image
      final fileExt = imageFile.path.split('.').last;
      final filePath = 'user-profile-images/$userId.$fileExt';

      // Upload the new image
      await supabase.storage
          .from('user-profile-images')
          .upload(filePath, imageFile);

      // Return the new file path
      return filePath;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Generate a signed URL for profile image
  Future<String?> getSignedUrl(String filePath) async {
    try {
      final signedUrl = await supabase.storage
          .from('user-profile-images')
          .createSignedUrl(filePath, 60 * 60 * 24); // 24-hour expiration
      return signedUrl;
    } catch (e) {
      print('Error generating signed URL: $e');
      return null;
    }
  }

  // Delete the profile image for the user
  Future<void> deleteProfileImage(String filePath) async {
    try {
      await supabase.storage.from('user-profile-images').remove([filePath]);
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
}
