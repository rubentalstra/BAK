import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final File localImageFile;

  const FullScreenImage({
    super.key,
    required this.localImageFile,
  });

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
        child: Hero(
          tag: localImageFile.path,
          child: Image.file(
            localImageFile,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
