import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service for uploading, fetching, and managing profile images using Supabase.
class ImageUploadService {
  final SupabaseClient supabase;
  final Dio dio = Dio(); // Dio instance for handling HTTP requests

  ImageUploadService(this.supabase);

  static const int maxFileSizeInMB = 2; // Max file size allowed in MB
  static const int maxFileSizeInBytes =
      maxFileSizeInMB * 1024 * 1024; // Max file size in bytes
  static const Duration signedUrlCacheDuration =
      Duration(minutes: 30); // Signed URL cache duration

  /// Get the local path to store images on the device.
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Compute the hash of the image file for comparison purposes.
  Future<String> _computeImageHash(File imageFile) async {
    final bytes = await imageFile.readAsBytes(); // Read file bytes
    return sha256.convert(bytes).toString(); // Return SHA256 hash as a string
  }

  /// Check if a local image exists and if the hash matches the current filename.
  Future<File?> _getLocalImageIfUnchanged(String profileImage) async {
    final fileHash =
        profileImage.split('.').first; // Extract hash from the filename
    final fileExtension =
        profileImage.split('.').last; // Extract file extension
    final localImagePath = '${await _getLocalPath()}/$fileHash.$fileExtension';
    final localImage = File(localImagePath);

    // Return the local image if it exists, otherwise return null.
    return (await localImage.exists()) ? localImage : null;
  }

  /// Download an image and save it locally in the format hash.extension.
  Future<File?> _saveImageLocally(
      String signedUrl, String fileHash, String fileExtension) async {
    try {
      final path = '${await _getLocalPath()}/$fileHash.$fileExtension';
      final file = File(path); // Create the file
      final response =
          await dio.download(signedUrl, file.path); // Download the image

      if (response.statusCode == 200) {
        return file; // Return the file if successful
      }
      throw Exception('Failed to download image from $signedUrl');
    } catch (e) {
      print('Failed to save image locally: $e');
      return null;
    }
  }

  /// Upload a profile image to Supabase after comparing the hash with the existing image.
  Future<String?> uploadProfileImage(
      File imageFile, String? existingImage) async {
    try {
      // Check if the file size exceeds the predefined limit.
      if (imageFile.lengthSync() > maxFileSizeInBytes) {
        throw Exception('The file size exceeds the $maxFileSizeInMB MB limit.');
      }

      // Compute the hash of the new image file.
      final newImageHash = await _computeImageHash(imageFile);
      final fileExt = imageFile.path.split('.').last; // Extract file extension
      final newFilePath = 'user-profile-images/$newImageHash.$fileExt';

      // If there is an existing image, compare hashes to avoid redundant uploads.
      if (existingImage != null && existingImage.contains('.')) {
        final existingImageHash = existingImage.split('.').first;
        if (existingImageHash == newImageHash) {
          print('Image hash matches, no need to upload.');
          return null; // No upload is needed as the image is the same
        }

        // Delete the old image from Supabase storage.
        await deleteProfileImage(existingImage);
      }

      // Upload the new image to Supabase storage.
      await supabase.storage
          .from('user-profile-images')
          .upload(newFilePath, imageFile);

      // Return the new image filename if successful.
      return '$newImageHash.$fileExt';
    } catch (e) {
      print('Error uploading profile image: $e');

      // Throw a specific error message without the "Exception" prefix.
      throw Exception(
          'Failed to upload profile image: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  /// Fetch or download a profile image based on the given filename.
  Future<File?> fetchOrDownloadProfileImage(String profileImage) async {
    if (!profileImage.contains('.')) {
      print('Invalid profile image format');
      return null;
    }

    // Check if the local image exists and has the same hash.
    final localImage = await _getLocalImageIfUnchanged(profileImage);
    if (localImage != null) {
      // Return the local image if it exists.
      return localImage;
    }

    // Download and save the image if it has changed.
    return await _downloadAndSaveImage(profileImage);
  }

  /// Download an image and save it locally if not already cached.
  Future<File?> _downloadAndSaveImage(String profileImage) async {
    final fileHash = profileImage.split('.').first; // Extract file hash
    final fileExtension =
        profileImage.split('.').last; // Extract file extension
    final signedUrl =
        await _getSignedUrl(profileImage); // Get the signed URL for download

    if (signedUrl != null) {
      return await _saveImageLocally(
          signedUrl, fileHash, fileExtension); // Save image locally
    } else {
      print('Failed to fetch signed URL for $profileImage');
      return null;
    }
  }

  /// Generate a signed URL for the profile image to securely fetch it from Supabase storage.
  Future<String?> _getSignedUrl(String profileImage) async {
    try {
      final filePath =
          'user-profile-images/$profileImage'; // File path in Supabase storage
      return await supabase.storage.from('user-profile-images').createSignedUrl(
          filePath, signedUrlCacheDuration.inSeconds); // Generate signed URL
    } catch (e) {
      print('Error generating signed URL: $e');
      return null;
    }
  }

  /// Delete a profile image from both Supabase and local storage.
  Future<void> deleteProfileImage(String profileImage) async {
    if (!profileImage.contains('.')) {
      print('Invalid profile image format');
      return;
    }

    final fileHash = profileImage.split('.').first; // Extract file hash
    final fileExtension =
        profileImage.split('.').last; // Extract file extension
    final filePath =
        'user-profile-images/$fileHash.$fileExtension'; // Construct file path

    try {
      // Delete the image from Supabase storage.
      await supabase.storage.from('user-profile-images').remove([filePath]);
      print('Profile image deleted from Supabase: $filePath');

      // Delete the local image file.
      final localImagePath =
          '${await _getLocalPath()}/$fileHash.$fileExtension';
      final localFile = File(localImagePath);
      if (await localFile.exists()) {
        await localFile.delete();
        print('Deleted local image: $localImagePath');
      }
    } catch (e) {
      print('Error during profile image deletion: $e');
    }
  }
}
