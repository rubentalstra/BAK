import 'package:bak_tracker/models/association_achievement_model.dart';
import 'package:equatable/equatable.dart';

class AssociationMemberAchievementModel extends Equatable {
  final String id;
  final String? memberId;
  final AssociationAchievementModel achievement;
  final DateTime assignedAt;

  const AssociationMemberAchievementModel({
    required this.id,
    this.memberId,
    required this.achievement,
    required this.assignedAt,
  });

  factory AssociationMemberAchievementModel.fromMap(Map<String, dynamic> map) {
    return AssociationMemberAchievementModel(
        id: map['id'] ?? 'Unknown Achievement ID',
        memberId: map['member_id'] ?? 'Unknown Member ID',
        achievement: AssociationAchievementModel.fromMap(map['achievement_id']),
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
