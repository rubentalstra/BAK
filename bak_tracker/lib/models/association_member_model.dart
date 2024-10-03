import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/models/member_achievement_model.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:equatable/equatable.dart';

class AssociationMemberModel extends Equatable {
  final String id;
  final UserModel user;
  final String associationId;
  final String? role;
  final PermissionsModel permissions;
  final DateTime joinedAt;
  final int baksReceived;
  final int baksConsumed;
  final int betsWon;
  final int betsLost;
  final List<MemberAchievementModel> achievements;

  const AssociationMemberModel({
    required this.id,
    required this.user,
    required this.associationId,
    this.role,
    required this.permissions,
    required this.joinedAt,
    this.baksReceived = 0,
    this.baksConsumed = 0,
    this.betsWon = 0,
    this.betsLost = 0,
    this.achievements = const [],
  });

  // Factory method to create the model from a Map
  factory AssociationMemberModel.fromMap(Map<String, dynamic> map) {
    return AssociationMemberModel(
      id: map['id'],
      user: UserModel.fromMap(map['user_id']),
      associationId: map['association_id'],
      role: map['role'],
      permissions: PermissionsModel.fromMap(map['permissions'] ?? {}),
      joinedAt: DateTime.parse(map['joined_at']),
      baksReceived: map['baks_received'] ?? 0,
      baksConsumed: map['baks_consumed'] ?? 0,
      betsWon: map['bets_won'] ?? 0,
      betsLost: map['bets_lost'] ?? 0,
      achievements: List<MemberAchievementModel>.from(
        (map['member_achievements'] as List).map(
          (achievementMap) => MemberAchievementModel.fromMap(achievementMap),
        ),
      ),
    );
  }

  // Convert the model to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user.toMap(),
      'association_id': associationId,
      'role': role,
      'permissions': permissions.toMap(),
      'joined_at': joinedAt.toIso8601String(),
      'baks_received': baksReceived,
      'baks_consumed': baksConsumed,
      'bets_won': betsWon,
      'bets_lost': betsLost,
      'achievements': achievements.map((e) => e.toMap()).toList(),
    };
  }

  // Method to check if the member has a specific permission
  bool hasPermission(PermissionEnum permission) {
    return permissions.hasPermission(permission);
  }

  @override
  List<Object?> get props => [
        id,
        associationId,
        user,
        role,
        permissions,
        joinedAt,
        baksReceived,
        baksConsumed,
        betsWon,
        betsLost,
        achievements,
      ];
}
