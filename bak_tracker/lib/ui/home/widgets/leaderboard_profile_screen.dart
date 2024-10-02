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

  // Method to show full-screen image view
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
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align content to the start
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context),
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey,
                    backgroundImage: localImageFile != null
                        ? FileImage(localImageFile!)
                        : null,
                    // If there's no image, show initials
                    child: localImageFile == null
                        ? Text(
                            member.user.name[0]
                                .toUpperCase(), // Display the first letter of the username
                            style: const TextStyle(
                              fontSize:
                                  70, // Make the text size appropriate for the avatar size
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildAchievementsSection(context), // Achievements at the top
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

  // Method to build the achievements section with matching padding and margin
  Widget _buildAchievementsSection(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.all(16.0), // Match the padding of other sections
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align achievements to the start
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
                  // Using Wrap to display badges in rows
                  spacing: 10,
                  runSpacing: 8,
                  children: member.achievements.map((achievement) {
                    return GestureDetector(
                      onTap: () =>
                          _showAchievementDetails(context, achievement),
                      child: _buildAchievementBadge(achievement),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // Badge for each achievement with a good design using colors and icons
  Widget _buildAchievementBadge(MemberAchievementModel achievement) {
    return Chip(
      avatar: const Icon(Icons.star, color: Colors.white), // Add a star icon
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Role', member.role, Icons.supervisor_account),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Chucked', member.baksConsumed,
                    FontAwesomeIcons.wineBottle),
                _buildStatColumn('BAK Debt', member.baksReceived,
                    FontAwesomeIcons.beerMugEmpty),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                    'Bets Won', member.betsWon, Icons.emoji_events),
                _buildStatColumn(
                    'Bets Lost', member.betsLost, FontAwesomeIcons.dice),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
}
