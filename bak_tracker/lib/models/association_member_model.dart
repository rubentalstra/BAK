class AssociationMemberModel {
  final String userId;
  final String associationId;
  final String roleTitle;
  final DateTime joinedAt;

  AssociationMemberModel({
    required this.userId,
    required this.associationId,
    required this.roleTitle,
    required this.joinedAt,
  });

  factory AssociationMemberModel.fromMap(Map<String, dynamic> map) {
    return AssociationMemberModel(
      userId: map['user_id'],
      associationId: map['association_id'],
      roleTitle: map['role_title'],
      joinedAt: DateTime.parse(map['joined_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'association_id': associationId,
      'role_title': roleTitle,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
