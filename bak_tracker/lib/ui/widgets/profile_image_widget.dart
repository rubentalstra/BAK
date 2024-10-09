import 'dart:io';
import 'package:flutter/material.dart';

class ProfileImageWidget extends StatelessWidget {
  final String? profileImageUrl;
  final String userName;
  final Future<File?> Function(String) fetchProfileImage;
  final double radius; // Customizable radius for the profile image
  final Color backgroundColor; // Background color for the profile image

  const ProfileImageWidget({
    super.key,
    required this.profileImageUrl,
    required this.userName,
    required this.fetchProfileImage,
    this.radius = 24.0,
    this.backgroundColor =
        const Color.fromRGBO(158, 158, 158, 1), // Default grey color
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _fetchImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor,
            child: const CircularProgressIndicator(),
          );
        }

        final imageFile = snapshot.data;
        return CircleAvatar(
          radius: radius,
          backgroundColor: imageFile == null ? backgroundColor : null,
          backgroundImage: imageFile != null ? FileImage(imageFile) : null,
          child: imageFile == null
              ? Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: radius, // Adjust font size based on radius
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<File?> _fetchImage() {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return fetchProfileImage(profileImageUrl!);
    }
    return Future.value(null);
  }
}
