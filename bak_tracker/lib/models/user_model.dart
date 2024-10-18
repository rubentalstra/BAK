import 'package:bak_tracker/models/user_achievement_model.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String? bio; // Nullable
  final String? fcmToken; // Nullable
  final String? profileImage; // Nullable
  final int
      alcoholStreak; // Current streak of days tracking alcohol consumption
  final int
      highestAlcoholStreak; // Highest streak of days tracking alcohol consumption
  final DateTime?
      lastDrinkConsumedAt; // Timestamp of the last drink logged by the user
  final List<UserAchievementModel> achievements; // List of achievements
  final bool notificationsEnabled; // New: Whether notifications are enabled
  final bool
      streakNotificationsEnabled; // New: Whether streak notifications are enabled

  const UserModel({
    required this.id,
    required this.name,
    this.bio, // Nullable
    this.fcmToken, // Nullable
    this.profileImage, // Nullable
    this.alcoholStreak = 0, // Default to 0 if not provided
    this.highestAlcoholStreak = 0, // Default to 0 if not provided
    this.lastDrinkConsumedAt, // Nullable
    this.achievements = const [],
    this.notificationsEnabled = false, // Default to false if not provided
    this.streakNotificationsEnabled = false, // Default to false if not provided
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? 'Unknown ID',
      name: map['name'] ?? 'Unknown Name',
      bio: map['bio'], // Nullable
      fcmToken: map['fcm_token'], // Nullable
      profileImage: map['profile_image'], // Nullable
      alcoholStreak: map['alcohol_streak'] ?? 0,
      highestAlcoholStreak: map['highest_alcohol_streak'] ?? 0,
      lastDrinkConsumedAt: map['last_drink_consumed_at'] != null
          ? DateTime.parse(map['last_drink_consumed_at'])
          : null,
      achievements: (map['user_achievements'] as List<dynamic>?)
              ?.map((achievementMap) =>
                  UserAchievementModel.fromMap(achievementMap))
              .toList() ??
          [], // Convert achievements or default to empty list
      notificationsEnabled: map['notifications_enabled'] ?? false, // New field
      streakNotificationsEnabled:
          map['streak_notification_enabled'] ?? false, // New field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'fcm_token': fcmToken,
      'profile_image': profileImage,
      'alcohol_streak': alcoholStreak,
      'highest_alcohol_streak': highestAlcoholStreak,
      'last_drink_consumed_at': lastDrinkConsumedAt?.toIso8601String(),
      'achievements': achievements.map((e) => e.toMap()).toList(),
      'notifications_enabled': notificationsEnabled, // New field
      'streak_notification_enabled': streakNotificationsEnabled, // New field
    };
  }

  UserModel copyWith({
    String? name,
    String? bio,
    String? fcmToken,
    String? profileImage,
    int? alcoholStreak,
    int? highestAlcoholStreak,
    DateTime? lastDrinkConsumedAt,
    List<UserAchievementModel>? achievements,
    bool? notificationsEnabled,
    bool? streakNotificationsEnabled,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      fcmToken: fcmToken ?? this.fcmToken,
      profileImage: profileImage ?? this.profileImage,
      alcoholStreak: alcoholStreak ?? this.alcoholStreak,
      highestAlcoholStreak: highestAlcoholStreak ?? this.highestAlcoholStreak,
      lastDrinkConsumedAt: lastDrinkConsumedAt ?? this.lastDrinkConsumedAt,
      achievements: achievements ?? this.achievements,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      streakNotificationsEnabled:
          streakNotificationsEnabled ?? this.streakNotificationsEnabled,
    );
  }

  // Calculate whether to show the hourglass (last activity between 24 and 36 hours ago)
  bool shouldShowHourglass() {
    if (lastDrinkConsumedAt == null) return false;
    final durationSinceLastActivity =
        DateTime.now().difference(lastDrinkConsumedAt!);
    return durationSinceLastActivity > Duration(hours: 24) &&
        durationSinceLastActivity <= Duration(hours: 36) &&
        alcoholStreak > 0;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        bio,
        fcmToken,
        profileImage,
        alcoholStreak,
        highestAlcoholStreak,
        lastDrinkConsumedAt,
        achievements,
        notificationsEnabled, // Added to props
        streakNotificationsEnabled, // Added to props
      ];
}
