import 'dart:io';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_member_achievement_model.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:bak_tracker/ui/widgets/hourglass_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/widgets/full_screen_profile_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class LeaderboardProfileScreen extends StatefulWidget {
  final AssociationMemberModel member;
  final File? localImageFile;

  const LeaderboardProfileScreen({
    super.key,
    required this.member,
    this.localImageFile,
  });

  @override
  LeaderboardProfileScreenState createState() =>
      LeaderboardProfileScreenState();
}

class LeaderboardProfileScreenState extends State<LeaderboardProfileScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  void _showFullScreenImage() {
    if (widget.localImageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FullScreenImage(localImageFile: widget.localImageFile!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final user = member.user;

    return Scaffold(
      appBar: _buildAppBar(user),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user),
            _buildStreakSection(user),
            _buildAchievementsSection(),
            _buildBioSection(user),
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(UserModel user) {
    return AppBar(
      title: Text(user.name),
      centerTitle: true,
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    final memberRole = widget.member.role ?? 'Member';
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showFullScreenImage,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey[400],
                backgroundImage: widget.localImageFile != null
                    ? FileImage(widget.localImageFile!)
                    : null,
                child: widget.localImageFile == null
                    ? Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 70,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              memberRole,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakSection(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(FontAwesomeIcons.fire,
                  color: Colors.deepOrangeAccent, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak: ${user.alcoholStreak} days',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Highest Streak: ${user.highestAlcoholStreak} days',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.member.user.shouldShowHourglass())
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: HourglassIcon(duration: const Duration(seconds: 3)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = widget.member.achievements;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Achievements'),
          achievements.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: const Text('No achievements earned yet.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return GestureDetector(
                      onTap: () => _showAchievementDetails(achievement),
                      child: _buildAchievementCard(achievement),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(AssociationMemberAchievementModel achievement) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.orangeAccent, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                achievement.achievement.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Column(
        children: [
          _buildSectionHeader('Bio'),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.info_outline,
                  color: AppColors.lightSecondary),
              title: Text(user.bio ?? 'No bio available'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final member = widget.member;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          _buildSectionHeader('Statistics'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildStatTile(
                  icon: FontAwesomeIcons.wineBottle,
                  title: 'Chucked',
                  value: member.baksConsumed.toString(),
                ),
                _buildDivider(),
                _buildStatTile(
                  icon: FontAwesomeIcons.beerMugEmpty,
                  title: 'BAK Debt',
                  value: member.baksReceived.toString(),
                ),
                _buildDivider(),
                _buildStatTile(
                  icon: Icons.emoji_events,
                  title: 'Bets Won',
                  value: member.betsWon.toString(),
                ),
                _buildDivider(),
                _buildStatTile(
                  icon: FontAwesomeIcons.dice,
                  title: 'Bets Lost',
                  value: member.betsLost.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.lightSecondary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.lightSecondary,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.lightSecondary,
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(AssociationMemberAchievementModel achievement) {
    final localDate = achievement.assignedAt.toLocal();
    final formattedDate = DateFormat('HH:mm dd-MM-yyyy').format(localDate);

    showModalBottomSheet(
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              ),
              const SizedBox(height: 10),
              Text(
                achievement.achievement.description ??
                    'No description available.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Earned on: $formattedDate',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
