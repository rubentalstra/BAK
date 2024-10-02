import 'dart:io';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/member_achievement_model.dart';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/widgets/full_screen_profile_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class LeaderboardProfileScreen extends StatelessWidget {
  final AssociationMemberModel member;
  final File? localImageFile;

  const LeaderboardProfileScreen({
    super.key,
    required this.member,
    this.localImageFile,
  });

  void _showFullScreenImage(BuildContext context) {
    if (localImageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FullScreenImage(localImageFile: localImageFile!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(member.user.name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(context),
              const SizedBox(height: 10),
              _buildAchievementsSection(context),
              const SizedBox(height: 10),
              _buildProfileCard(),
              const SizedBox(height: 10),
              _buildStatsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Profile image display logic with reusable method
  Widget _buildProfileImage(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _showFullScreenImage(context),
        child: CircleAvatar(
          radius: 80,
          backgroundColor: Colors.grey,
          backgroundImage:
              localImageFile != null ? FileImage(localImageFile!) : null,
          child: localImageFile == null
              ? Text(
                  member.user.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 12),
          member.achievements.isEmpty
              ? const Text('No achievements earned yet.')
              : Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: member.achievements
                      .map((achievement) => GestureDetector(
                            onTap: () =>
                                _showAchievementDetails(context, achievement),
                            child: _buildAchievementBadge(achievement),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  // Reusable method for achievement badge
  Widget _buildAchievementBadge(MemberAchievementModel achievement) {
    return Chip(
      avatar: const Icon(Icons.star, color: Colors.white),
      label: Text(achievement.achievement.name),
      backgroundColor: Colors.orangeAccent,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Role', member.role ?? 'No Role available',
                Icons.supervisor_account),
            const SizedBox(height: 12),
            _buildInfoRow(
                'Bio', member.user.bio ?? 'No bio available', Icons.info),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            _buildStatsRow([
              _buildStatColumn(
                  'Chucked', member.baksConsumed, FontAwesomeIcons.wineBottle),
              _buildStatColumn('BAK Debt', member.baksReceived,
                  FontAwesomeIcons.beerMugEmpty),
            ]),
            const SizedBox(height: 24),
            _buildStatsRow([
              _buildStatColumn('Bets Won', member.betsWon, Icons.emoji_events),
              _buildStatColumn(
                  'Bets Lost', member.betsLost, FontAwesomeIcons.dice),
            ]),
          ],
        ),
      ),
    );
  }

  // Reusable method for info row
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Reusable method for stats row
  Widget _buildStatsRow(List<Widget> columns) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: columns,
    );
  }

  // Reusable method for stat column
  Widget _buildStatColumn(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 36),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Reusable method for achievement header
  Widget _buildAchievementHeader(MemberAchievementModel achievement) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.orangeAccent, size: 28),
        const SizedBox(width: 12),
        Text(
          achievement.achievement.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  // Reusable method for achievement details
  Widget _buildAchievementDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Method to show achievement details in a modal bottom sheet
  void _showAchievementDetails(
      BuildContext context, MemberAchievementModel achievement) {
    final localDate = achievement.assignedAt.toLocal();
    final formattedDate = DateFormat('HH:mm dd-MM-yyyy').format(localDate);

    showModalBottomSheet(
      backgroundColor: AppColors.cardBackground,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.orangeAccent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    achievement.achievement.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Description:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                achievement.achievement.description ??
                    'No description available',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Earned on: $formattedDate',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
