import 'package:bak_tracker/models/achievement_model.dart';
import 'package:equatable/equatable.dart';

class MemberAchievementModel extends Equatable {
  final String id;
  final String? memberId;
  final AchievementModel achievement;
  final DateTime assignedAt;

  const MemberAchievementModel({
    required this.id,
    this.memberId,
    required this.achievement,
    required this.assignedAt,
  });

  factory MemberAchievementModel.fromMap(Map<String, dynamic> map) {
    return MemberAchievementModel(
        id: map['id'] ?? 'Unknown Achievement ID',
        memberId: map['member_id'] ?? 'Unknown Member ID',
        achievement: AchievementModel.fromMap(map['achievement_id']),
        assignedAt: DateTime.parse(map['assigned_at']));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'achievement_id':
          achievement.toMap(), // Convert achievement back to a map
      'assigned_at': assignedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, memberId, achievement, assignedAt];
}
