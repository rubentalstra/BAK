import 'package:bak_tracker/models/achievement_model.dart';
import 'package:equatable/equatable.dart';

class UserAchievementModel extends Equatable {
  final String id;
  final String? userId;
  final AchievementModel achievement;
  final DateTime assignedAt;

  const UserAchievementModel({
    required this.id,
    this.userId,
    required this.achievement,
    required this.assignedAt,
  });

  factory UserAchievementModel.fromMap(Map<String, dynamic> map) {
    return UserAchievementModel(
        id: map['id'] ?? 'Unknown Achievement ID',
        userId: map['user_id'] ?? 'Unknown User ID',
        achievement: AchievementModel.fromMap(map['achievement_id']),
        assignedAt: DateTime.parse(map['assigned_at']));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievement.toMap(),
      'assigned_at': assignedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, achievement, assignedAt];
}
