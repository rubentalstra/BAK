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
  final bool isLoading;

  const LeaderboardWidget({
    super.key,
    required this.entries,
    required this.imageUploadService,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? _buildLoadingSkeleton()
        : ListView.separated(
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
          .fetchOrDownloadProfileImage(entry.profileImagePath!, version: 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 24.0,
            backgroundColor: Colors.grey,
            child: CircularProgressIndicator(),
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

  // Skeleton loading for the entire list item
  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      itemCount: 6, // Loading skeleton for 6 items
      separatorBuilder: (context, index) => Divider(
        height: 1.0,
        color: Colors.grey[300],
      ),
      itemBuilder: (context, index) {
        return Skeletonizer(
          enabled: true,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24.0,
                  backgroundColor: Colors.grey,
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeletonizer(
                        child: SizedBox(
                          height: 16.0,
                          width: 100.0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4.0)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Skeletonizer(
                        child: SizedBox(
                          height: 14.0,
                          width: 150.0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4.0)),
                            ),
                          ),
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
