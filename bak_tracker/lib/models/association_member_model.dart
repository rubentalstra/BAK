import 'dart:convert';
import 'package:bak_tracker/core/const/permissions.dart';
import 'package:equatable/equatable.dart';

class AssociationMemberModel extends Equatable {
  final String userId;
  final String? name;
  final String? bio;
  final String? profileImage;
  final String associationId;
  final String role;
  final Map<String, dynamic> permissions;
  final DateTime joinedAt;
  final int baksReceived;
  final int baksConsumed;
  final int betsWon;
  final int betsLost;

  const AssociationMemberModel({
    required this.userId,
    this.name,
    this.bio,
    this.profileImage,
    required this.associationId,
    required this.role,
    required this.permissions,
    required this.joinedAt,
    required this.baksReceived,
    required this.baksConsumed,
    required this.betsWon,
    required this.betsLost,
  });

  factory AssociationMemberModel.fromMap(Map<String, dynamic> map) {
    return AssociationMemberModel(
      userId: map['user_id'],
      name: map['name'],
      bio: map['bio'],
      profileImage: map['profile_image'],
      associationId: map['association_id'],
      role: map['role'],
      permissions: map['permissions'] is String
          ? jsonDecode(map['permissions']) as Map<String, dynamic>
          : map['permissions'] as Map<String, dynamic>,
      joinedAt: DateTime.parse(map['joined_at']),
      baksReceived: map['baks_received'],
      baksConsumed: map['baks_consumed'],
      betsWon: map['bets_won'],
      betsLost: map['bets_lost'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'bio': bio,
      'profile_image': profileImage,
      'association_id': associationId,
      'role': role,
      'permissions': jsonEncode(permissions),
      'joined_at': joinedAt.toIso8601String(),
      'baks_received': baksReceived,
      'baks_consumed': baksConsumed,
      'bets_won': betsWon,
      'bets_lost': betsLost,
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

  // Equatable override to simplify equality comparison
  @override
  List<Object?> get props => [
        userId,
        name,
        bio,
        profileImage,
        associationId,
        role,
        permissions,
        joinedAt,
        baksReceived,
        baksConsumed,
        betsWon,
        betsLost,
      ];
}
