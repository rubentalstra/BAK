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
  static const Duration signedUrlCacheDuration = Duration(minutes: 30);

  // Get the local path to store images
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Save image locally with the same name as on Supabase (including version)
  Future<File> _saveImageLocally(String url, String fileName) async {
    final path = await _getLocalPath();
    final file = File('$path/$fileName');
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
      return 0;
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

      int currentVersion = _extractVersion(existingFilePath);
      int newVersion = currentVersion + 1;
      final fileExt = imageFile.path.split('.').last;
      final newFilePath = 'user-profile-images/$userId-v$newVersion.$fileExt';

      // Upload the new image
      await supabase.storage
          .from('user-profile-images')
          .upload(newFilePath, imageFile);

      // Delete the old image if the new one is uploaded successfully
      if (existingFilePath != null && existingFilePath.isNotEmpty) {
        await deleteProfileImage(existingFilePath);
        await _deleteLocalImage(existingFilePath); // Delete local old version
      }

      return newFilePath;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Delete old local image
  Future<void> _deleteLocalImage(String filePath) async {
    final localImage = await getLocalImage(filePath);
    if (localImage != null && await localImage.exists()) {
      await localImage.delete();
      print('Deleted old local image: ${localImage.path}');
    }
  }

  // Fetch or download profile image, only if version is changed
  Future<File?> fetchOrDownloadProfileImage(String filePath) async {
    final localImage = await getLocalImage(filePath);
    int localVersion = _extractVersion(localImage?.path);
    int serverVersion = _extractVersion(filePath);

    // If local image version is the same as the server version, return local image
    if (localVersion == serverVersion && localImage != null) {
      print('Using cached local image version: $localVersion');
      return localImage;
    }

    // Fetch a new signed URL and download if the version has changed
    final signedUrl = await getSignedUrl(filePath);
    if (signedUrl != null) {
      return _saveImageLocally(
          signedUrl, filePath); // Save using the same file name
    }
    return null;
  }

  // Generate a signed URL for profile image
  Future<String?> getSignedUrl(String filePath) async {
    try {
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
      print('Image deleted successfully from Supabase: $filePath');

      // Now delete the local file as well
      await _deleteLocalImage(filePath);
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
}
