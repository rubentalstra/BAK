import 'dart:io';

import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:bak_tracker/services/image_upload_service.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final String? profileImagePath;
  final int baksConsumed;
  final int baksDebt;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    this.profileImagePath,
    required this.baksConsumed,
    required this.baksDebt,
  });

  LeaderboardEntry copyWith({
    int? rank,
    String? name,
    String? profileImagePath,
    int? baksConsumed,
    int? baksDebt,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      baksConsumed: baksConsumed ?? this.baksConsumed,
      baksDebt: baksDebt ?? this.baksDebt,
    );
  }
}

class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final ImageUploadService imageUploadService;
  final bool isLoading; // Indicates if it's in the loading state

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
          : _buildLeaderboardList(), // Show the leaderboard data when loaded
    );
  }

  Widget _buildLeaderboardList() {
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => Divider(
        height: 1.0,
        color: Colors.grey[300],
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileImage(entry, context),
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
                        color: Colors.black87,
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
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(LeaderboardEntry entry, BuildContext context) {
    if (entry.profileImagePath == null) {
      return const CircleAvatar(
        radius: 24.0,
        backgroundColor: Colors.grey,
        child: Icon(
          Icons.person,
          color: Colors.white,
        ),
      );
    }

    return FutureBuilder<File?>(
      future: imageUploadService
          .fetchOrDownloadProfileImage(entry.profileImagePath!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 24.0,
            backgroundColor: Colors.grey,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasData) {
          return CircleAvatar(
            radius: 24.0,
            backgroundImage: FileImage(snapshot.data!),
          );
        }

        return const CircleAvatar(
          radius: 24.0,
          backgroundColor: Colors.grey,
          child: Icon(
            Icons.person,
            color: Colors.white,
          ),
        );
      },
    );
  }

  // Skeleton loading for the entire list item with shimmer effect
  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      itemCount: 6, // Loading skeleton for 6 items
      separatorBuilder: (context, index) => Divider(
        height: 1.0,
        color: Colors.grey[300],
      ),
      itemBuilder: (context, index) {
        return Skeletonizer(
          effect: const ShimmerEffect(
            baseColor: Color(0xFFE0E0E0), // Equivalent to Colors.grey[300]
            highlightColor: Color(0xFFF5F5F5), // Equivalent to Colors.grey[100]
            duration: Duration(seconds: 1), // Adjust shimmer speed
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200], // Lighter grey for a softer feel
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
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        height: 14.0,
                        width: 150.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
