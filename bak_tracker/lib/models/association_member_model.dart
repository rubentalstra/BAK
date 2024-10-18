import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/models/association_member_achievement_model.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:equatable/equatable.dart';

class AssociationMemberModel extends Equatable {
  final String id;
  final UserModel user;
  final String associationId;
  final String? role;
  final PermissionsModel permissions;
  final DateTime? joinedAt;
  final int baksReceived;
  final int baksConsumed;
  final int betsWon;
  final int betsLost;
  final List<AssociationMemberAchievementModel> achievements;

  const AssociationMemberModel({
    required this.id,
    required this.user,
    required this.associationId,
    this.role,
    required this.permissions,
    this.joinedAt,
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
      joinedAt:
          map['joined_at'] != null ? DateTime.parse(map['joined_at']) : null,
      baksReceived: map['baks_received'] ?? 0,
      baksConsumed: map['baks_consumed'] ?? 0,
      betsWon: map['bets_won'] ?? 0,
      betsLost: map['bets_lost'] ?? 0,
      achievements: List<AssociationMemberAchievementModel>.from(
        (map['association_member_achievements'] as List).map(
          (achievementMap) =>
              AssociationMemberAchievementModel.fromMap(achievementMap),
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
      'joined_at': joinedAt?.toIso8601String(),
      'baks_received': baksReceived,
      'baks_consumed': baksConsumed,
      'bets_won': betsWon,
      'bets_lost': betsLost,
      'achievements': achievements.map((e) => e.toMap()).toList(),
    };
  }

  // Add the copyWith method, now with the new fields included
  AssociationMemberModel copyWith({
    String? id,
    UserModel? user,
    String? associationId,
    String? role,
    PermissionsModel? permissions,
    DateTime? joinedAt,
    int? baksReceived,
    int? baksConsumed,
    int? betsWon,
    int? betsLost,
    List<AssociationMemberAchievementModel>? achievements,
  }) {
    return AssociationMemberModel(
      id: id ?? this.id,
      user: user ?? this.user,
      associationId: associationId ?? this.associationId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt ?? this.joinedAt,
      baksReceived: baksReceived ?? this.baksReceived,
      baksConsumed: baksConsumed ?? this.baksConsumed,
      betsWon: betsWon ?? this.betsWon,
      betsLost: betsLost ?? this.betsLost,
      achievements: achievements ?? this.achievements,
    );
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
