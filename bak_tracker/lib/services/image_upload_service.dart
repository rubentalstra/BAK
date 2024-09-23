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

  // Save image locally from a URL
  Future<File> _saveImageLocally(String url, String fileName) async {
    try {
      final path = await _getLocalPath();
      final file = File('$path/$fileName');
      final response = await dio.download(url, file.path);

      if (response.statusCode == 200) {
        return file;
      } else {
        throw Exception('Error downloading image from $url');
      }
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }

  // Check if local image exists
  Future<File?> getLocalImage(String fileName) async {
    final file = File('${await _getLocalPath()}/$fileName');
    return (await file.exists()) ? file : null;
  }

  // Extract version number from file path
  int _extractVersion(String? filePath) {
    final match = RegExp(r'-v(\d+)').firstMatch(filePath ?? '');
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  // Upload profile image with version increment
  Future<String?> uploadProfileImage(
      File imageFile, String userId, String? existingFilePath) async {
    try {
      if (imageFile.lengthSync() > maxFileSizeInBytes) {
        throw Exception('File size exceeds $maxFileSizeInMB MB limit');
      }

      final newVersion = _extractVersion(existingFilePath) + 1;
      final fileExt = imageFile.path.split('.').last;
      final newFilePath = 'user-profile-images/$userId-v$newVersion.$fileExt';

      // Upload the new image
      await supabase.storage
          .from('user-profile-images')
          .upload(newFilePath, imageFile);

      // Delete old image if new one is uploaded successfully
      await _deletePreviousImage(existingFilePath);

      return newFilePath;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Delete previous image both locally and on Supabase
  Future<void> _deletePreviousImage(String? filePath) async {
    if (filePath != null && filePath.isNotEmpty) {
      await deleteProfileImage(filePath);
      await _deleteLocalImage(filePath);
    }
  }

  // Delete local image
  Future<void> _deleteLocalImage(String filePath) async {
    final localImage = await getLocalImage(filePath);
    if (localImage != null) {
      await localImage.delete();
      print('Deleted local image: ${localImage.path}');
    }
  }

  // Fetch or download profile image if the version has changed
  Future<File?> fetchOrDownloadProfileImage(String filePath) async {
    final localImage = await getLocalImage(filePath);
    final localVersion = _extractVersion(localImage?.path);
    final serverVersion = _extractVersion(filePath);

    if (localVersion == serverVersion && localImage != null) {
      print('Using cached local image version: $localVersion');
      return localImage;
    }

    // Download new version if server version is newer
    final signedUrl = await getSignedUrl(filePath);
    return signedUrl != null ? _saveImageLocally(signedUrl, filePath) : null;
  }

  // Generate signed URL for profile image
  Future<String?> getSignedUrl(String filePath) async {
    try {
      return await supabase.storage
          .from('user-profile-images')
          .createSignedUrl(filePath, signedUrlCacheDuration.inSeconds);
    } catch (e) {
      print('Error generating signed URL: $e');
      return null;
    }
  }

  // Delete profile image from both Supabase and locally
  Future<void> deleteProfileImage(String filePath) async {
    if (filePath.isEmpty) return;

    try {
      // Delete from Supabase storage
      await supabase.storage.from('user-profile-images').remove([filePath]);
      print('Image deleted from Supabase: $filePath');

      // Delete locally
      await _deleteLocalImage(filePath);
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
}
