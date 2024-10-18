import 'package:bak_tracker/bloc/user/user_event.dart';
import 'package:bak_tracker/models/user_achievement_model.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart';
import 'package:bak_tracker/ui/widgets/profile_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/bloc/user/user_bloc.dart';
import 'package:bak_tracker/bloc/user/user_state.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ValueNotifier<IconData> _hourglassIconNotifier;
  final ImageUploadService imageUploadService =
      ImageUploadService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _hourglassIconNotifier =
        ValueNotifier<IconData>(FontAwesomeIcons.hourglassStart);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Profile'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.gear),
            tooltip: 'Settings',
            onPressed: () {
              // Navigate to settings screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserLoaded) {
            return _buildProfileContent(context, state.user);
          } else if (state is UserError) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          } else {
            return const Center(child: Text('No user data found'));
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImage(context, user),
            const SizedBox(height: 20),
            _buildStreakAndHourglass(user),
            const SizedBox(height: 20),
            _buildAlcoholTrackingSection(context, user),
            const SizedBox(height: 20),
            _buildAchievementsSection(context, user),
            const SizedBox(height: 20),
            _buildProfileCard(user),
            const SizedBox(height: 20),
            _buildSettingsSection(context),
          ],
        ),
      ),
    );
  }

  // Profile image display logic
  Widget _buildProfileImage(BuildContext context, UserModel user) {
    return Center(
      child: GestureDetector(
        onTap: null,
        child: ProfileImageWidget(
          profileImageUrl: user.profileImage,
          userName: user.name,
          fetchProfileImage: imageUploadService.fetchOrDownloadProfileImage,
          radius: 80.0,
          backgroundColor: Colors.grey, // You can customize the background
        ),
      ),
    );
  }

  Widget _buildStreakAndHourglass(UserModel user) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.trophy,
                color: Colors.orangeAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Highest Streak: ${user.highestAlcoholStreak} days',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.fire,
                color: Colors.deepOrangeAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              '${user.alcoholStreak} days',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrangeAccent),
            ),
            if (user.shouldShowHourglass())
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: ValueListenableBuilder<IconData>(
                  valueListenable: _hourglassIconNotifier,
                  builder: (context, icon, _) {
                    return Icon(icon, color: Colors.orangeAccent, size: 28);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(BuildContext context, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent),
        ),
        const SizedBox(height: 12),
        user.achievements.isEmpty
            ? const Text('No achievements earned yet.')
            : Wrap(
                spacing: 10,
                runSpacing: 8,
                children: user.achievements
                    .map((achievement) => GestureDetector(
                          onTap: () =>
                              _showAchievementDetails(context, achievement),
                          child: _buildAchievementBadge(achievement),
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildAchievementBadge(UserAchievementModel achievement) {
    return Chip(
      avatar: const Icon(Icons.star, color: Colors.white),
      label: Text(achievement.achievement.name),
      backgroundColor: Colors.orangeAccent,
      labelStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                'Bio', user.bio ?? 'No bio available', Icons.info_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildAlcoholTrackingSection(BuildContext context, UserModel user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alcoholism Tracking',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent),
            ),
            const SizedBox(height: 10),
            // Button to log alcohol
            ElevatedButton.icon(
              onPressed: () {
                // Dispatch event to log alcohol consumption
                context.read<UserBloc>().add(LogAlcoholConsumption('Beer'));
              },
              icon: const Icon(FontAwesomeIcons.champagneGlasses),
              label: const Text('Log Alcohol Consumption'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('Change language preferences'),
              onTap: () {
                // Open language selection modal
              },
            ),
            SwitchListTile(
              title: const Text('Enable Streak Notifications'),
              subtitle: const Text('Receive notifications for your streaks'),
              value: true, // replace with actual value
              onChanged: (value) {
                // Handle notification switch toggle
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AuthenticationBloc>().signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const Icon(FontAwesomeIcons.arrowRightFromBracket),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
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
                    color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAchievementDetails(
      BuildContext context, UserAchievementModel achievement) {
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
                      'No description available'),
              const SizedBox(height: 16),
              Text(
                'Earned on: $formattedDate',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementHeader(UserAchievementModel achievement) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.orangeAccent, size: 28),
        const SizedBox(width: 12),
        Text(
          achievement.achievement.name,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent),
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
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
