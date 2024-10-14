import 'dart:io';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/leaderboard_entry.dart';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_profile_screen.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/ui/widgets/profile_image_widget.dart';

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

        return GestureDetector(
          onTap: () => _navigateToProfileScreen(context, member),
          child: _buildEntry(context, entry),
        );
      },
    );
  }

  void _navigateToProfileScreen(
      BuildContext context, AssociationMemberModel member) async {
    File? imageFile;

    // Fetch the profile image if the URL is provided, otherwise pass null
    if (member.user.profileImage != null &&
        member.user.profileImage!.isNotEmpty) {
      imageFile = await imageUploadService
          .fetchOrDownloadProfileImage(member.user.profileImage!);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaderboardProfileScreen(
          member: member,
          localImageFile: imageFile, // Pass the image file or null
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, LeaderboardEntry entry) {
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
          ProfileImageWidget(
            profileImageUrl: member.user.profileImage,
            userName: member.user.name,
            fetchProfileImage: imageUploadService.fetchOrDownloadProfileImage,
            radius: 24.0,
            backgroundColor: Colors.grey, // You can customize the background
          ),
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
                    _buildInfoText(
                        'Chucked', member.baksConsumed, Colors.green[700]),
                    const SizedBox(width: 16.0),
                    _buildInfoText('BAK', member.baksReceived, Colors.red[700]),
                  ],
                ),
              ],
            ),
          ),
          Text(
            entry.rank.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String label, int count, Color? color) {
    return Text(
      '$label: $count',
      style: TextStyle(
        fontSize: 14.0,
        color: color,
        fontWeight: FontWeight.w400,
      ),
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
                    _buildSkeletonBox(100.0, 16.0),
                    const SizedBox(height: 8.0),
                    _buildSkeletonBox(150.0, 14.0),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBox(double width, double height) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.lightPrimaryVariant,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
