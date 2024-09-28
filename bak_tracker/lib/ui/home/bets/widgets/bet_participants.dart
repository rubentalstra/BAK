import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bak_tracker/services/image_upload_service.dart';

class BetParticipants extends StatelessWidget {
  final Map<String, dynamic> bet;
  final ImageUploadService imageUploadService;

  const BetParticipants({
    super.key,
    required this.bet,
    required this.imageUploadService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            FutureBuilder<File?>(
              future: (bet['bet_creator_id']['profile_image'] != null &&
                      bet['bet_creator_id']['profile_image'].isNotEmpty)
                  ? imageUploadService.fetchOrDownloadProfileImage(
                      bet['bet_creator_id']['profile_image'])
                  : Future.value(null),
              builder: (context, snapshot) {
                final creatorImage = snapshot.data;
                return _buildProfileImage(
                    creatorImage, bet['bet_creator_id']['name']);
              },
            ),
            Positioned(
              left: 30,
              child: FutureBuilder<File?>(
                future: (bet['bet_receiver_id']['profile_image'] != null &&
                        bet['bet_receiver_id']['profile_image'].isNotEmpty)
                    ? imageUploadService.fetchOrDownloadProfileImage(
                        bet['bet_receiver_id']['profile_image'])
                    : Future.value(null),
                builder: (context, snapshot) {
                  final receiverImage = snapshot.data;
                  return _buildProfileImage(
                      receiverImage, bet['bet_receiver_id']['name']);
                },
              ),
            ),
          ],
        ),
        const SizedBox(width: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creator: ${bet['bet_creator_id']['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Receiver: ${bet['bet_receiver_id']['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileImage(File? imageFile, String userName) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: imageFile == null ? Colors.grey[300] : null,
      backgroundImage: imageFile != null ? FileImage(imageFile) : null,
      child: imageFile == null
          ? Text(
              userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            )
          : null,
    );
  }
}
