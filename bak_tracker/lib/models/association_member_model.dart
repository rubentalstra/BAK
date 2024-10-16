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
  final DateTime? lastBakActivity;
  final int bakStreak;
  final int highestStreak;

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
    this.lastBakActivity,
    this.bakStreak = 0,
    this.highestStreak = 0,
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
      lastBakActivity: map['last_bak_activity'] != null
          ? DateTime.parse(map['last_bak_activity'])
          : null,
      bakStreak: map['bak_streak'] ?? 0,
      highestStreak: map['highest_streak'] ?? 0,
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
      'last_bak_activity': lastBakActivity?.toIso8601String(),
      'bak_streak': bakStreak,
      'highest_streak': highestStreak,
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
    DateTime? lastBakActivity,
    int? bakStreak,
    int? highestStreak,
    List<MemberAchievementModel>? achievements,
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
      lastBakActivity: lastBakActivity ?? this.lastBakActivity,
      bakStreak: bakStreak ?? this.bakStreak,
      highestStreak: highestStreak ?? this.highestStreak,
      achievements: achievements ?? this.achievements,
    );
  }

  // Method to check if the member has a specific permission
  bool hasPermission(PermissionEnum permission) {
    return permissions.hasPermission(permission);
  }

  // Calculate whether to show the hourglass (last activity between 24 and 36 hours ago)
  bool shouldShowHourglass() {
    if (lastBakActivity == null) return false;
    final durationSinceLastActivity =
        DateTime.now().difference(lastBakActivity!);
    return durationSinceLastActivity > Duration(hours: 24) &&
        durationSinceLastActivity <= Duration(hours: 36) &&
        bakStreak > 0;
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
        lastBakActivity,
        bakStreak,
        highestStreak,
        achievements,
      ];
}
