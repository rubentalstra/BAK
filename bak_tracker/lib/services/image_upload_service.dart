import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient supabase;
  final Dio dio = Dio();

  ImageUploadService(this.supabase);

  static const int maxFileSizeInMB = 2;
  static const int maxFileSizeInBytes = maxFileSizeInMB * 1024 * 1024;
  static const Duration signedUrlCacheDuration = Duration(minutes: 30);

  // Get the local path to store images
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Compute hash of the image file
  Future<String> _computeImageHash(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  // Check if the local image exists and matches the current filename
  Future<File?> _getLocalImageIfUnchanged(String profileImage) async {
    final fileHash = profileImage.split('.').first;
    final fileExtension = profileImage.split('.').last;
    final localImagePath = '${await _getLocalPath()}/$fileHash.$fileExtension';
    final localImage = File(localImagePath);

    // If local image exists, return it, otherwise return null
    return (await localImage.exists()) ? localImage : null;
  }

  // Download and save image locally using hash.extension format
  Future<File?> _saveImageLocally(
      String signedUrl, String fileHash, String fileExtension) async {
    try {
      final path = '${await _getLocalPath()}/$fileHash.$fileExtension';
      final file = File(path);
      final response = await dio.download(signedUrl, file.path);

      if (response.statusCode == 200) {
        return file;
      }
      throw Exception('Failed to download image from $signedUrl');
    } catch (e) {
      print('Failed to save image locally: $e');
      return null;
    }
  }

  // Upload a profile image, compare hashes, and save with hash.extension format
  Future<String?> uploadProfileImage(
      File imageFile, String? existingImage) async {
    try {
      if (imageFile.lengthSync() > maxFileSizeInBytes) {
        throw Exception('File size exceeds $maxFileSizeInMB MB limit');
      }

      final newImageHash = await _computeImageHash(imageFile);
      final fileExt = imageFile.path.split('.').last;
      final newFilePath = 'user-profile-images/$newImageHash.$fileExt';

      // If there's an existing image, compare hash and delete the old image
      if (existingImage != null && existingImage.contains('.')) {
        final existingImageHash = existingImage.split('.').first;
        if (existingImageHash == newImageHash) {
          print('Image hash matches, no need to upload.');
          return null; // No upload needed, image is the same
        }
        await deleteProfileImage(existingImage);
      }

      // Upload the new image to Supabase storage
      await supabase.storage
          .from('user-profile-images')
          .upload(newFilePath, imageFile);
      return '$newImageHash.$fileExt'; // Return new hash and extension after successful upload
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Fetch or download a profile image, update it if needed
  Future<File?> fetchOrDownloadProfileImage(String profileImage) async {
    if (!profileImage.contains('.')) {
      print('Invalid profile image format');
      return null;
    }

    // Check if the local image exists and has the same hash
    final localImage = await _getLocalImageIfUnchanged(profileImage);
    if (localImage != null) {
      // Return the local image if it exists
      return localImage;
    }

    // Download and save the image if it has changed
    return await _downloadAndSaveImage(profileImage);
  }

  // Download image and save locally
  Future<File?> _downloadAndSaveImage(String profileImage) async {
    final fileHash = profileImage.split('.').first;
    final fileExtension = profileImage.split('.').last;
    final signedUrl = await _getSignedUrl(profileImage);

    if (signedUrl != null) {
      return await _saveImageLocally(signedUrl, fileHash, fileExtension);
    } else {
      print('Failed to fetch signed URL for $profileImage');
      return null;
    }
  }

  // Generate signed URL for profile image
  Future<String?> _getSignedUrl(String profileImage) async {
    try {
      final filePath = 'user-profile-images/$profileImage';
      return await supabase.storage
          .from('user-profile-images')
          .createSignedUrl(filePath, signedUrlCacheDuration.inSeconds);
    } catch (e) {
      print('Error generating signed URL: $e');
      return null;
    }
  }

  // Delete profile image from both Supabase and local storage
  Future<void> deleteProfileImage(String profileImage) async {
    if (!profileImage.contains('.')) {
      print('Invalid profile image format');
      return;
    }

    final fileHash = profileImage.split('.').first;
    final fileExtension = profileImage.split('.').last;
    final filePath = 'user-profile-images/$fileHash.$fileExtension';

    try {
      // Delete the file from Supabase storage
      await supabase.storage.from('user-profile-images').remove([filePath]);
      print('Profile image deleted from Supabase: $filePath');

      // Delete the image locally
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
