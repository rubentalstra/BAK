import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient supabase;
  final Dio dio = Dio();

  ImageUploadService(this.supabase);

  static const int maxFileSizeInMB = 2;
  static const int maxFileSizeInBytes = maxFileSizeInMB * 1024 * 1024;
  static const Duration signedUrlCacheDuration =
      Duration(minutes: 30); // Reduced the expiration

  // Get the local path to store images
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Save image locally
  Future<File> _saveImageLocally(String url, String fileName) async {
    final path = await _getLocalPath();
    final file = File('$path/$fileName');

    // Download the image and save it locally
    final response = await dio.download(url, file.path);
    if (response.statusCode == 200) {
      return file;
    } else {
      throw Exception('Error downloading image');
    }
  }

  // Get local image path if it exists
  Future<File?> getLocalImage(String fileName) async {
    final path = await _getLocalPath();
    final file = File('$path/$fileName');

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  // Extract version number from the file path
  int _extractVersion(String? filePath) {
    if (filePath == null || !filePath.contains('-v')) {
      return 0; // Default to 0 if no version found
    }

    final versionMatch = RegExp(r'-v(\d+)').firstMatch(filePath);
    return versionMatch != null ? int.parse(versionMatch.group(1)!) : 0;
  }

  // Upload profile image to 'user-profile-images' bucket with version increment
  Future<String?> uploadProfileImage(
      File imageFile, String userId, String? existingFilePath) async {
    try {
      if (imageFile.lengthSync() > maxFileSizeInBytes) {
        throw Exception('File size exceeds the 2MB limit');
      }

      // Increment the version based on the current file path
      int currentVersion = _extractVersion(existingFilePath);
      int newVersion = currentVersion + 1;

      // Generate new file path with incremented version
      final fileExt = imageFile.path.split('.').last;
      final newFilePath = 'user-profile-images/$userId-v$newVersion.$fileExt';

      // Upload the new image
      await supabase.storage
          .from('user-profile-images')
          .upload(newFilePath, imageFile);

      // Now that the new image is successfully uploaded, delete the old one
      if (existingFilePath != null && existingFilePath.isNotEmpty) {
        await deleteProfileImage(existingFilePath);
      }

      return newFilePath;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Fetch or download profile image
  Future<File?> fetchOrDownloadProfileImage(String filePath,
      {int version = 1}) async {
    // Check if the image exists locally
    final localImage = await getLocalImage('$filePath-v$version');
    if (localImage != null) {
      return localImage;
    }

    // Fetch a new signed URL (with a short expiration) and download it
    final signedUrl = await getSignedUrl(filePath, version: version);
    if (signedUrl != null) {
      return _saveImageLocally(signedUrl, '$filePath-v$version');
    }
    return null;
  }

  // Generate a signed URL for profile image with a short expiration time
  Future<String?> getSignedUrl(String filePath, {int version = 1}) async {
    try {
      // Generate a new signed URL with short expiration
      final signedUrl = await supabase.storage
          .from('user-profile-images')
          .createSignedUrl(filePath, signedUrlCacheDuration.inSeconds);

      return signedUrl;
    } catch (e) {
      print('Error generating signed URL: $e');
      return null;
    }
  }

  // Delete profile image for user
  Future<void> deleteProfileImage(String filePath) async {
    try {
      if (filePath.isEmpty) {
        throw Exception("File path is empty, cannot delete image.");
      }

      // Attempt to delete the file from Supabase storage
      await supabase.storage.from('user-profile-images').remove([filePath]);

      print('Image deleted successfully: $filePath');
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
}
