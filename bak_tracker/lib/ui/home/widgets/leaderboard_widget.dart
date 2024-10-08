import 'dart:io';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/leaderboard_entry.dart';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_profile_screen.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/core/themes/colors.dart';

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
      child:
          isLoading ? _buildLoadingSkeleton() : _buildLeaderboardList(context),
    );
  }

  Widget _buildLeaderboardList(BuildContext context) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final member = entry.member;

        return FutureBuilder<File?>(
          future: _loadProfileImage(member),
          builder: (context, snapshot) {
            final imageFile = snapshot.data;

            return GestureDetector(
              onTap: () => _navigateToProfileScreen(context, member, imageFile),
              child: _buildEntry(entry, imageFile),
            );
          },
        );
      },
    );
  }

  Future<File?> _loadProfileImage(AssociationMemberModel member) async {
    if (member.user.profileImage == null || member.user.profileImage!.isEmpty) {
      return null;
    }
    return await imageUploadService
        .fetchOrDownloadProfileImage(member.user.profileImage!);
  }

  void _navigateToProfileScreen(
      BuildContext context, AssociationMemberModel member, File? imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaderboardProfileScreen(
          member: member,
          localImageFile: imageFile,
        ),
      ),
    );
  }

  Widget _buildEntry(LeaderboardEntry entry, File? imageFile) {
    final member = entry.member;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(imageFile, member.user.name),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.user.name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Text(
                      'Chucked: ${member.baksConsumed}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      'BAK: ${member.baksReceived}',
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

  Widget _buildProfileImage(File? imageFile, String userName) {
    return CircleAvatar(
      radius: 24.0,
      backgroundColor: imageFile == null ? Colors.grey : Colors.transparent,
      backgroundImage: imageFile != null ? FileImage(imageFile) : null,
      child: imageFile == null
          ? Text(
              userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 9, // Loading skeleton for 9 items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
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
