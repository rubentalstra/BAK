import 'package:bak_tracker/models/user_achievement_model.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/profile/drink_history_screen.dart';
import 'package:bak_tracker/ui/profile/log_drink_screen.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart';
import 'package:bak_tracker/ui/widgets/profile_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/bloc/user/user_bloc.dart';
import 'package:bak_tracker/bloc/user/user_state.dart';
import 'package:bak_tracker/bloc/user/user_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImageUploadService imageUploadService =
      ImageUploadService(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Personal Profile'),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.gear),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildProfileImage(context, user),
        const SizedBox(height: 20),
        _buildStreakSection(user),
        const SizedBox(height: 20),
        _buildSectionHeader('Alcohol Tracking'),
        _buildLogDrinkButton(context),
        const SizedBox(height: 20),
        _buildDrinkHistoryButton(context, user.id),
        const SizedBox(height: 20),
        _buildAchievementsSection(context, user),
        const SizedBox(height: 20),
        _buildSectionHeader('Bio'),
        _buildProfileCard(user),
        _buildNotificationOptions(context, user),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.lightSecondary,
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context, UserModel user) {
    return Center(
      child: ProfileImageWidget(
        profileImageUrl: user.profileImage,
        userName: user.name,
        fetchProfileImage: imageUploadService.fetchOrDownloadProfileImage,
        radius: 80.0,
        backgroundColor: Colors.grey,
      ),
    );
  }

  Widget _buildStreakSection(UserModel user) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.trophy, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(
              'Highest Streak: ${user.highestAlcoholStreak} days',
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
            Icon(FontAwesomeIcons.fire, color: Colors.deepOrangeAccent),
            const SizedBox(width: 8),
            Text(
              '${user.alcoholStreak} days',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrangeAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // New: Notification switches for enabling/disabling notifications
  Widget _buildNotificationOptions(BuildContext context, UserModel user) {
    return Column(
      children: [
        _buildOptionCard(
          context,
          icon: FontAwesomeIcons.bell,
          title: 'Enable Notifications',
          subtitle: 'Allow notifications from the app',
          trailing: Switch(
            value: user.notificationsEnabled,
            onChanged: (value) => _onNotificationToggle(context, value),
          ),
        ),
        _buildOptionCard(
          context,
          icon: FontAwesomeIcons.fire,
          title: 'Enable Streak Notifications',
          subtitle: 'Allow notifications for streak tracking',
          trailing: Switch(
            value: user.streakNotificationsEnabled,
            onChanged: (value) => _onStreakNotificationToggle(context, value),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.lightSecondary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }

  void _onNotificationToggle(BuildContext context, bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        context.read<UserBloc>().add(ToggleNotifications(true));
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else {
      context.read<UserBloc>().add(ToggleNotifications(false));
    }
  }

  void _onStreakNotificationToggle(BuildContext context, bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        context.read<UserBloc>().add(ToggleStreakNotifications(true));
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else {
      context.read<UserBloc>().add(ToggleStreakNotifications(false));
    }
  }

  Widget _buildLogDrinkButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LogDrinkScreen()),
        );
      },
      icon: const Icon(FontAwesomeIcons.champagneGlasses),
      label: const Text('Log Alcohol Consumption'),
    );
  }

  Widget _buildDrinkHistoryButton(BuildContext context, String userId) {
    return ElevatedButton.icon(
      icon: const Icon(FontAwesomeIcons.clockRotateLeft),
      label: const Text('View Drink Log History'),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DrinkHistoryScreen(userId: userId),
          ),
        );
      },
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
            color: Colors.orangeAccent,
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading:
            const Icon(Icons.info_outline, color: AppColors.lightSecondary),
        title: const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.bio ?? 'No bio available'),
      ),
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
                'Description: ${achievement.achievement.description ?? 'No description available'}',
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
