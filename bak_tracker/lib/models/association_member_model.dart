import 'dart:convert';

class AssociationMemberModel {
  final String userId;
  final String? name;
  final String associationId;
  final String role;
  final Map<String, dynamic> permissions;
  final DateTime joinedAt;

  AssociationMemberModel({
    required this.userId,
    required this.name,
    required this.associationId,
    required this.role,
    required this.permissions,
    required this.joinedAt,
  });

  factory AssociationMemberModel.fromMap(Map<String, dynamic> map) {
    return AssociationMemberModel(
      userId: map['user_id'],
      name: map['name'],
      associationId: map['association_id'],
      role: map['role'],
      permissions: map['permissions'] != null
          ? jsonDecode(map['permissions']) as Map<String, dynamic>
          : {},
      joinedAt: DateTime.parse(map['joined_at']),
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
    };
  }

  bool get canInviteMembers => permissions['invite_members'] ?? false;
  bool get canRemoveMembers => permissions['remove_members'] ?? false;
  bool get canUpdateRole => permissions['update_role'] ?? false;
  bool get canUpdateBakAmount => permissions['update_bak_amount'] ?? false;
  bool get canApproveBakTaken => permissions['approve_bak_taken'] ?? false;
}
