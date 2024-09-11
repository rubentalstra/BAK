class UserPermissionModel {
  final String userId;
  final String associationId;
  final int permissionId;

  UserPermissionModel({
    required this.userId,
    required this.associationId,
    required this.permissionId,
  });

  factory UserPermissionModel.fromMap(Map<String, dynamic> map) {
    return UserPermissionModel(
      userId: map['user_id'],
      associationId: map['association_id'],
      permissionId: map['permission_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'association_id': associationId,
      'permission_id': permissionId,
    };
  }
}
