import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_profile_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/core/themes/colors.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final String? bio;
  final String? role;
  final String? profileImage;
  final int baksConsumed;
  final int baksDebt;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    this.bio,
    this.role,
    this.profileImage,
    required this.baksConsumed,
    required this.baksDebt,
  });

  LeaderboardEntry copyWith({
    int? rank,
    String? name,
    String? bio,
    String? role,
    String? profileImage,
    int? baksConsumed,
    int? baksDebt,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      baksConsumed: baksConsumed ?? this.baksConsumed,
      baksDebt: baksDebt ?? this.baksDebt,
    );
  }
}

class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final ImageUploadService imageUploadService;
  final bool isLoading;

  const LeaderboardWidget({
    super.key,
    required this.entries,
    required this.imageUploadService,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: isLoading
          ? _buildLoadingSkeleton() // Show skeleton when loading
          : _buildLeaderboardList(
              context), // Show the leaderboard data when loaded
    );
  }

  Widget _buildLeaderboardList(BuildContext context) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];

        return FutureBuilder<File?>(
          future: entry.profileImage == null || entry.profileImage!.isEmpty
              ? Future.value(null) // If no profile image, return null
              : imageUploadService.fetchOrDownloadProfileImage(
                  entry.profileImage!,
                ),
          builder: (context, snapshot) {
            final imageFile = snapshot.data;

            // Wrap the entry with GestureDetector to allow navigation to profile page
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderboardProfileScreen(
                      username: entry.name,
                      localImageFile:
                          imageFile, // Pass the local image if it exists
                      bio: entry.bio,
                      role: entry.role,
                      baksConsumed: entry.baksConsumed,
                      baksDebt: entry.baksDebt,
                    ),
                  ),
                );
              },
              child: _buildEntry(entry, imageFile),
            );
          },
        );
      },
    );
  }

  Widget _buildEntry(LeaderboardEntry entry, File? imageFile) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground, // Updated card background
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(
              imageFile), // Display profile image or default icon
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Text(
                      'Chucked: ${entry.baksConsumed}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      'BAK: ${entry.baksDebt}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                entry.rank.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show profile image or default icon
  Widget _buildProfileImage(File? imageFile) {
    if (imageFile == null) {
      // Default icon for missing image
      return const CircleAvatar(
        radius: 24.0,
        backgroundColor: Colors.grey,
        child: Icon(
          size: 30.0,
          Icons.person,
          color: Colors.white,
        ),
      );
    }

    // Display the profile image
    return CircleAvatar(
      radius: 24.0,
      backgroundImage: FileImage(imageFile),
    );
  }

  // Updated skeleton with card background color
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 6, // Loading skeleton for 6 items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground, // Updated card background
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 24.0,
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16.0,
                      width: 100.0,
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimaryVariant,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 14.0,
                      width: 150.0,
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimaryVariant,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
