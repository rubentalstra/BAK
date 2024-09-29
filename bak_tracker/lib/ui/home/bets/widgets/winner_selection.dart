import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bak_tracker/services/image_upload_service.dart';

class WinnerSelection extends StatelessWidget {
  final Map<String, dynamic> bet;
  final Function(Map<String, dynamic>, String) onWinnerSelected;
  final ImageUploadService imageUploadService;

  const WinnerSelection({
    super.key,
    required this.bet,
    required this.onWinnerSelected,
    required this.imageUploadService,
  });

  @override
  Widget build(BuildContext context) {
    String? selectedWinner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select the Winner:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder<File?>(
              future: _getProfileImage(bet['bet_creator_id']['profile_image']),
              builder: (context, snapshot) {
                final creatorImage = snapshot.data;
                return _buildSelectableWinnerOption(
                  userId: bet['bet_creator_id']['id'],
                  userName: bet['bet_creator_id']['name'],
                  profileImage: creatorImage,
                  isSelected: selectedWinner == bet['bet_creator_id']['id'],
                  onTap: () {
                    selectedWinner = bet['bet_creator_id']['id'];
                    onWinnerSelected(bet, selectedWinner!);
                  },
                );
              },
            ),
            const Text(
              'vs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            FutureBuilder<File?>(
              future: _getProfileImage(bet['bet_receiver_id']['profile_image']),
              builder: (context, snapshot) {
                final receiverImage = snapshot.data;
                return _buildSelectableWinnerOption(
                  userId: bet['bet_receiver_id']['id'],
                  userName: bet['bet_receiver_id']['name'],
                  profileImage: receiverImage,
                  isSelected: selectedWinner == bet['bet_receiver_id']['id'],
                  onTap: () {
                    selectedWinner = bet['bet_receiver_id']['id'];
                    onWinnerSelected(bet, selectedWinner!);
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<File?> _getProfileImage(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      return Future.value(null);
    } else {
      return imageUploadService.fetchOrDownloadProfileImage(profileImageUrl);
    }
  }

  Widget _buildSelectableWinnerOption({
    required String userId,
    required String userName,
    File? profileImage,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundImage:
                profileImage != null ? FileImage(profileImage) : null,
            backgroundColor: profileImage == null ? Colors.grey : null,
            child: profileImage == null
                ? Text(
                    _getInitials(userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Function to get the initials from the user's name
  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0].toUpperCase()}${nameParts[1][0].toUpperCase()}';
    } else {
      return nameParts[0][0].toUpperCase();
    }
  }
}
