import 'dart:convert';
import 'package:bak_tracker/core/const/permissions.dart';
import 'package:bak_tracker/models/member_achievement_model.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:equatable/equatable.dart';

class AssociationMemberModel extends Equatable {
  final String id;
  final UserModel user;
  final String associationId;
  final String role;
  final Map<String, dynamic> permissions;
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
    required this.role,
    required this.permissions,
    required this.joinedAt,
    required this.baksReceived,
    required this.baksConsumed,
    required this.betsWon,
    required this.betsLost,
    this.achievements = const [],
  });

  factory AssociationMemberModel.fromMap(Map<String, dynamic> map) {
    return AssociationMemberModel(
      id: map['id'] ?? 'Unknown ID',
      user: UserModel.fromMap(map['user_id']),
      associationId: map['association_id'],
      role: map['role'],
      permissions: map['permissions'] != null
          ? (map['permissions'] is String
              ? jsonDecode(map['permissions']) as Map<String, dynamic>
              : map['permissions'] as Map<String, dynamic>)
          : {}, // Default to empty permissions if null
      joinedAt: map['joined_at'] != null
          ? DateTime.parse(map['joined_at'])
          : DateTime.now(), // Default to current time if null
      baksReceived: map['baks_received'] ?? 0,
      baksConsumed: map['baks_consumed'] ?? 0,
      betsWon: map['bets_won'] ?? 0,
      betsLost: map['bets_lost'] ?? 0,
      achievements: map['member_achievements'] != null
          ? List<MemberAchievementModel>.from(
              (map['member_achievements'] as List).map(
                (achievementMap) =>
                    MemberAchievementModel.fromMap(achievementMap),
              ),
            )
          : [], // Default to empty achievements list if null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user.toMap(),
      'association_id': associationId,
      'role': role,
      'permissions': jsonEncode(permissions),
      'joined_at': joinedAt.toIso8601String(),
      'baks_received': baksReceived,
      'baks_consumed': baksConsumed,
      'bets_won': betsWon,
      'bets_lost': betsLost,
      'achievements': achievements.map((e) => e.toMap()).toList(),
    };
  }

  // Permissions checkers
  bool get hasAllPermissions => hasPermission(permissions, 'hasAllPermissions');
  bool get canManagePermissions =>
      hasAllPermissions || hasPermission(permissions, 'canManagePermissions');
  bool get canInviteMembers =>
      hasAllPermissions || hasPermission(permissions, 'canInviteMembers');
  bool get canRemoveMembers =>
      hasAllPermissions || hasPermission(permissions, 'canRemoveMembers');
  bool get canManageRoles =>
      hasAllPermissions || hasPermission(permissions, 'canManageRoles');
  bool get canManageBaks =>
      hasAllPermissions || hasPermission(permissions, 'canManageBaks');
  bool get canApproveBaks =>
      hasAllPermissions || hasPermission(permissions, 'canApproveBaks');
  bool get canManageAchievements =>
      hasAllPermissions || hasPermission(permissions, 'canManageAchievements');

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
