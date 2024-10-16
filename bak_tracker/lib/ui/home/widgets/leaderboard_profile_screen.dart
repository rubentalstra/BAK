import 'dart:io';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/member_achievement_model.dart';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/widgets/full_screen_profile_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class LeaderboardProfileScreen extends StatefulWidget {
  final AssociationMemberModel member;
  final File? localImageFile;

  const LeaderboardProfileScreen(
      {super.key, required this.member, this.localImageFile});

  @override
  _LeaderboardProfileScreenState createState() =>
      _LeaderboardProfileScreenState();
}

class _LeaderboardProfileScreenState extends State<LeaderboardProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ValueNotifier<IconData> _hourglassIconNotifier;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller for the hourglass icon
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 3), // Total duration of the hourglass animation cycle
    )..repeat(); // Repeat the animation infinitely

    // Set initial hourglass icon
    _hourglassIconNotifier =
        ValueNotifier<IconData>(FontAwesomeIcons.hourglassStart);

    // Update the icon based on animation progress
    _controller.addListener(() {
      final progress = _controller.value;

      if (progress < 0.33) {
        _hourglassIconNotifier.value = FontAwesomeIcons.hourglassStart;
      } else if (progress < 0.66) {
        _hourglassIconNotifier.value = FontAwesomeIcons.hourglassHalf;
      } else if (progress < 1.0) {
        _hourglassIconNotifier.value = FontAwesomeIcons.hourglassEnd;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hourglassIconNotifier.dispose();
    super.dispose();
  }

  void _showFullScreenImage(BuildContext context) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.user.name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(context),
              const SizedBox(height: 20),
              _buildStreakAndHourglass(),
              const SizedBox(height: 20),
              _buildAchievementsSection(context),
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

  // Profile image display logic with reusable method
  Widget _buildProfileImage(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _showFullScreenImage(context),
        child: CircleAvatar(
          radius: 80,
          backgroundColor: Color.fromRGBO(158, 158, 158, 1),
          backgroundImage: widget.localImageFile != null
              ? FileImage(widget.localImageFile!)
              : null,
          child: widget.localImageFile == null
              ? Text(
                  widget.member.user.name[0].toUpperCase(),
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 12),
          widget.member.achievements.isEmpty
              ? const Text('No achievements earned yet.')
              : Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: widget.member.achievements
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

// Build the streak and hourglass widgets, and include the highest streak
  Widget _buildStreakAndHourglass() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Display the highest streak
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.trophy,
              color: Colors.orangeAccent,
              size: 24,
            ),
            const SizedBox(width: 8),

            // Highest Streak text
            Text(
              'Highest Streak: ${widget.member.highestStreak} ${widget.member.highestStreak == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flame icon for streaks
            Icon(
              FontAwesomeIcons.fire,
              color: Colors.deepOrangeAccent,
              size: 24,
            ),
            const SizedBox(width: 8),

            // Current Streak text
            Text(
              '${widget.member.bakStreak} ${widget.member.bakStreak == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrangeAccent,
              ),
            ),

            // Animated hourglass if streak is about to expire
            if (widget.member.shouldShowHourglass())
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: ValueListenableBuilder<IconData>(
                  valueListenable: _hourglassIconNotifier,
                  builder: (context, icon, _) {
                    return Icon(
                      icon,
                      color: Colors.orangeAccent,
                      size: 28,
                    );
                  },
                ),
              ),
          ],
        ),
      ],
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Role',
              widget.member.role ?? 'No role available',
              Icons.person,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Bio',
              widget.member.user.bio ?? 'No bio available',
              Icons.info_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
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
                widget.member.baksConsumed,
                FontAwesomeIcons.wineBottle,
              ),
              _buildStatColumn(
                'BAK Debt',
                widget.member.baksReceived,
                FontAwesomeIcons.beerMugEmpty,
              ),
            ]),
            const SizedBox(height: 24),
            _buildStatsRow([
              _buildStatColumn(
                'Bets Won',
                widget.member.betsWon,
                Icons.emoji_events,
              ),
              _buildStatColumn(
                'Bets Lost',
                widget.member.betsLost,
                FontAwesomeIcons.dice,
              ),
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

  // Method to show achievement details in a modal bottom sheet
  void _showAchievementDetails(
    BuildContext context,
    MemberAchievementModel achievement,
  ) {
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
}
