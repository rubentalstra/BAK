import 'dart:io';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/leaderboard_entry.dart';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_profile_screen.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/ui/widgets/profile_image_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    if (isLoading) {
      return _buildLoadingSkeleton();
    } else {
      if (entries.isEmpty) {
        return const Center(
          child: Text('No data available'),
        );
      }

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
            backgroundColor: Colors.grey,
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
                    _buildInfoIconText(FontAwesomeIcons.fire,
                        member.user.alcoholStreak, Colors.deepOrangeAccent),
                    const SizedBox(width: 16.0),
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
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoIconText(IconData icon, int count, Color? color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 2.0),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14.0,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
              // Profile image skeleton
              const CircleAvatar(
                radius: 24.0,
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name skeleton
                    _buildSkeletonBox(100.0, 16.0),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        // Streak skeleton
                        _buildSkeletonIconAndText(60.0),
                        const SizedBox(width: 16.0),
                        // Baks Consumed skeleton
                        _buildSkeletonBox(50.0, 14.0),
                        const SizedBox(width: 16.0),
                        // Bak Received skeleton
                        _buildSkeletonBox(50.0, 14.0),
                      ],
                    ),
                  ],
                ),
              ),
              // Rank skeleton
              _buildSkeletonBox(30.0, 16.0),
            ],
          ),
        );
      },
    );
  }

  // Helper function for skeleton with icon and text
  Widget _buildSkeletonIconAndText(double width) {
    return Row(
      children: [
        Container(
          width: 18.0,
          height: 18.0,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2.0),
        Container(
          height: 14.0,
          width: width - 20.0, // Adjust width to account for icon and spacing
          decoration: BoxDecoration(
            color: AppColors.lightPrimaryVariant,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ],
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
