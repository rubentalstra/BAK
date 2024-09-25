import 'dart:convert';

class AssociationMemberModel {
  final String userId;
  final String? name;
  final String? bio;
  final String? profileImagePath;
  final String associationId;
  final String role;
  final Map<String, dynamic> permissions;
  final DateTime joinedAt;
  final int baksReceived;
  final int baksConsumed;

  AssociationMemberModel({
    required this.userId,
    this.name,
    this.bio,
    this.profileImagePath,
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
      bio: map['bio'],
      profileImagePath: map['profile_image_path'],
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
      'bio': bio,
      'profile_image_path': profileImagePath,
      'association_id': associationId,
      'role': role,
      'permissions': jsonEncode(permissions),
      'joined_at': joinedAt.toIso8601String(),
      'baks_received': baksReceived,
      'baks_consumed': baksConsumed,
    };
  }

  // If all_permissions is true, all permissions should be true
  bool get hasAllPermissions => permissions['hasAllPermissions'] ?? false;

  bool get canManagePermissions =>
      hasAllPermissions || (permissions['canManagePermissions'] ?? false);
  bool get canInviteMembers =>
      hasAllPermissions || (permissions['canInviteMembers'] ?? false);
  bool get canRemoveMembers =>
      hasAllPermissions || (permissions['canRemoveMembers'] ?? false);
  bool get canManageRoles =>
      hasAllPermissions || (permissions['canManageRoles'] ?? false);
  bool get canManageBaks =>
      hasAllPermissions || (permissions['canManageBaks'] ?? false);
  bool get canApproveBaks =>
      hasAllPermissions || (permissions['canApproveBaks'] ?? false);
}
