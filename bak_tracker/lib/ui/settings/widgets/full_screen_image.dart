import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FullScreenImage extends StatelessWidget {
  final String localFileName;

  const FullScreenImage({
    super.key,
    required this.localFileName,
  });

  Future<File?> _getLocalImageFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localImagePath = '${directory.path}/$localFileName';
      final file = File(localImagePath);

      // Check if the local file exists
      if (await file.exists()) {
        return file;
      } else {
        return null;
      }
    } catch (e) {
      print('Error loading local image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: FutureBuilder<File?>(
          future: _getLocalImageFile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Show loading indicator
            }
            if (snapshot.hasData && snapshot.data != null) {
              return Hero(
                tag: localFileName, // Use local file name as Hero tag
                child: Image.file(
                  snapshot.data!,
                  fit: BoxFit.contain,
                ),
              );
            } else {
              return const Text('No image found',
                  style: TextStyle(color: Colors.white));
            }
          },
        ),
      ),
    );
  }
}
