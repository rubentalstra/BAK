import 'dart:io';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_member_achievement_model.dart';
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
  AnimationController? _controller;
  IconData? _hourglassIcon;

  @override
  void initState() {
    super.initState();
    if (widget.member.user.shouldShowHourglass()) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat();

      _controller!.addListener(_updateHourglassIcon);
      _updateHourglassIcon();
    }
  }

  void _updateHourglassIcon() {
    final progress = _controller!.value;
    setState(() {
      if (progress < 0.33) {
        _hourglassIcon = FontAwesomeIcons.hourglassStart;
      } else if (progress < 0.66) {
        _hourglassIcon = FontAwesomeIcons.hourglassHalf;
      } else {
        _hourglassIcon = FontAwesomeIcons.hourglassEnd;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: Text(user.name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              const SizedBox(height: 20),
              _buildStreakAndHourglass(),
              const SizedBox(height: 20),
              _buildAchievementsSection(),
              const SizedBox(height: 20),
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildStatsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final user = widget.member.user;
    return Center(
        child: GestureDetector(
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
    ));
  }

  Widget _buildAchievementsSection() {
    final achievements = widget.member.achievements;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Association Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 12),
          achievements.isEmpty
              ? const Text('No achievements earned yet.')
              : Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: achievements
                      .map((achievement) => GestureDetector(
                            onTap: () => _showAchievementDetails(achievement),
                            child: _buildAchievementBadge(achievement),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStreakAndHourglass() {
    final user = widget.member.user;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Highest Streak
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.trophy,
              color: Colors.orangeAccent,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Highest Streak: ${user.highestAlcoholStreak} ${user.highestAlcoholStreak == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Current Streak and Hourglass
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.fire,
              color: Colors.deepOrangeAccent,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '${user.alcoholStreak} ${user.alcoholStreak == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrangeAccent,
              ),
            ),
            if (widget.member.user.shouldShowHourglass())
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: _hourglassIcon != null
                    ? Icon(
                        _hourglassIcon,
                        color: Colors.orangeAccent,
                        size: 28,
                      )
                    : const SizedBox(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(AssociationMemberAchievementModel achievement) {
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
    final member = widget.member;
    final user = member.user;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              'Role',
              member.role ?? 'No role available',
              Icons.person,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Bio',
              user.bio ?? 'No bio available',
              Icons.info_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final member = widget.member;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            _buildStatsRow([
              _buildStatColumn(
                'Chucked',
                member.baksConsumed,
                FontAwesomeIcons.wineBottle,
              ),
              _buildStatColumn(
                'BAK Debt',
                member.baksReceived,
                FontAwesomeIcons.beerMugEmpty,
              ),
            ]),
            const SizedBox(height: 24),
            _buildStatsRow([
              _buildStatColumn(
                'Bets Won',
                member.betsWon,
                Icons.emoji_events,
              ),
              _buildStatColumn(
                'Bets Lost',
                member.betsLost,
                FontAwesomeIcons.dice,
              ),
            ]),
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

  Widget _buildStatsRow(List<Widget> columns) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: columns,
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

  void _showAchievementDetails(AssociationMemberAchievementModel achievement) {
    final localDate = achievement.assignedAt.toLocal();
    final formattedDate = DateFormat('HH:mm dd-MM-yyyy').format(localDate);

    showModalBottomSheet(
      backgroundColor: AppColors.cardBackground,
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAchievementHeader(achievement),
              const SizedBox(height: 10),
              _buildAchievementDetail(
                'Description',
                achievement.achievement.description ??
                    'No description available',
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

  Widget _buildAchievementHeader(
      AssociationMemberAchievementModel achievement) {
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
}
