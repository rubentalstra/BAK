import 'dart:io';
import 'package:bak_tracker/core/utils/signed_url_cache.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient supabase;

  ImageUploadService(this.supabase);

  // Constants
  static const int maxFileSizeInMB = 2;
  static const int maxFileSizeInBytes = maxFileSizeInMB * 1024 * 1024;

  // Cache duration for signed URLs (e.g., 24 hours)
  static const Duration signedUrlCacheDuration = Duration(hours: 24);

  // Upload profile image to 'user-profile-images' bucket
  Future<String?> uploadProfileImage(
      File imageFile, String userId, String? existingFilePath) async {
    try {
      if (imageFile.lengthSync() > maxFileSizeInBytes) {
        throw Exception('File size exceeds the 2MB limit');
      }

      // Delete the existing profile image if it exists
      if (existingFilePath != null && existingFilePath.isNotEmpty) {
        // Clear the cache for the old image URL before removing the file
        await SignedUrlCache.deleteCachedUrl(existingFilePath);

        // Remove the existing file from Supabase storage
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

  // Generate a signed URL for profile image with persistent caching
  Future<String?> getSignedUrl(String filePath) async {
    // Check if the URL is cached persistently
    final cachedUrl = await SignedUrlCache.getCachedUrl(filePath);
    if (cachedUrl != null) {
      return cachedUrl;
    }

    try {
      // Generate a new signed URL
      final signedUrl = await supabase.storage
          .from('user-profile-images')
          .createSignedUrl(filePath, signedUrlCacheDuration.inSeconds);

      // Cache the signed URL persistently
      await SignedUrlCache.cacheUrl(
          filePath, signedUrl, signedUrlCacheDuration);

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
      await SignedUrlCache.deleteCachedUrl(filePath);
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
}
