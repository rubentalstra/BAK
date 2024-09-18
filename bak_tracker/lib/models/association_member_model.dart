import 'dart:convert';

class AssociationMemberModel {
  final String userId;
  final String? name;
  final String associationId;
  final String role;
  final Map<String, dynamic> permissions;
  final DateTime joinedAt;
  final int baksReceived;
  final int baksConsumed;

  AssociationMemberModel({
    required this.userId,
    this.name,
    required this.associationId,
    required this.role,
    required this.permissions,
    required this.joinedAt,
    required this.baksReceived,
    required this.baksConsumed,
  });

  factory AssociationMemberModel.fromMap(Map<String, dynamic> map) {
    return AssociationMemberModel(
      userId: map['user_id'],
      name: map['name'],
      associationId: map['association_id'],
      role: map['role'],
      permissions: map['permissions'] is String
          ? jsonDecode(map['permissions']) as Map<String, dynamic>
          : map['permissions'] as Map<String, dynamic>,
      joinedAt: DateTime.parse(map['joined_at']),
      baksReceived: map['baks_received'],
      baksConsumed: map['baks_consumed'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'association_id': associationId,
      'role': role,
      'permissions': jsonEncode(permissions),
      'joined_at': joinedAt.toIso8601String(),
      'baks_received': baksReceived,
      'baks_consumed': baksConsumed,
    };
  }

  bool get canUpdatePermissions => permissions['update_permissions'] ?? false;
  bool get canInviteMembers => permissions['invite_members'] ?? false;
  bool get canRemoveMembers => permissions['remove_members'] ?? false;
  bool get canUpdateRole => permissions['update_role'] ?? false;
  bool get canUpdateBakAmount => permissions['update_bak_amount'] ?? false;
  bool get canApproveBakTaken => permissions['approve_bak_taken'] ?? false;
}
