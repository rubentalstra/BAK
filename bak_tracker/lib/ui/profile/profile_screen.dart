import 'package:bak_tracker/core/const/drink_types.dart';
import 'package:bak_tracker/models/user_achievement_model.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/profile/log_drink_screen.dart';
import 'package:bak_tracker/ui/profile/total_consumption_screen.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart';
import 'package:bak_tracker/ui/widgets/hourglass_icon_widget.dart';
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
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
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
            return _buildProfileContent(context, state);
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
      centerTitle: true, // Center the title for better aesthetics
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

  Widget _buildProfileContent(BuildContext context, UserLoaded state) {
    final user = state.user;
    final totalConsumption = state.totalConsumption;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(user),
          _buildStreakSection(user),
          _buildActionButtons(user.id, totalConsumption),
          _buildAchievementsSection(user),
          _buildBioSection(user),
          _buildNotificationOptions(user),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            const SizedBox(height: 12),
            ProfileImageWidget(
              profileImageUrl: user.profileImage,
              userName: user.name,
              fetchProfileImage: imageUploadService.fetchOrDownloadProfileImage,
              radius: 60.0,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
              if (user.shouldShowHourglass())
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

  Widget _buildActionButtons(
      String userId, Map<DrinkType, int> totalConsumption) {
    final totalDrinks =
        totalConsumption.values.fold<int>(0, (sum, value) => sum + value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const LogDrinkScreen()),
                );
              },
              icon: const Icon(FontAwesomeIcons.champagneGlasses, size: 20),
              label: const Text(
                'Log Drink',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        TotalConsumptionScreen(userId: userId),
                  ),
                );
              },
              icon: const Icon(FontAwesomeIcons.chartBar, size: 20),
              label: Text(
                'Total: $totalDrinks',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          _buildSectionHeader('Achievements'),
          user.achievements.isEmpty
              ? const Text('No achievements earned yet.')
              : SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: user.achievements.map((achievement) {
                      return GestureDetector(
                        onTap: () =>
                            _showAchievementDetails(context, achievement),
                        child: _buildAchievementCard(achievement),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(UserAchievementModel achievement) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.orangeAccent, size: 32),
            const SizedBox(height: 8),
            Text(
              achievement.achievement.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
        ));
  }

  Widget _buildNotificationOptions(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          _buildSectionHeader('Notifications'),
          _buildOptionCard(
            icon: FontAwesomeIcons.bell,
            title: 'Enable Notifications',
            subtitle: 'Allow notifications from the app',
            value: user.notificationsEnabled,
            onChanged: (value) => _onNotificationToggle(context, value),
          ),
          _buildOptionCard(
            icon: FontAwesomeIcons.fire,
            title: 'Streak Notifications',
            subtitle: 'Receive updates on your streaks',
            value: user.streakNotificationsEnabled,
            onChanged: (value) => _onStreakNotificationToggle(context, value),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        secondary: Icon(icon, color: AppColors.lightSecondary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

  void _onNotificationToggle(BuildContext context, bool value) async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      context.read<UserBloc>().add(ToggleNotifications(value));
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _onStreakNotificationToggle(BuildContext context, bool value) async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      context.read<UserBloc>().add(ToggleStreakNotifications(value));
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _showAchievementDetails(
      BuildContext context, UserAchievementModel achievement) {
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
