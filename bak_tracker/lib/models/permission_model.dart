class PermissionModel {
  final int id;
  final String permissionName;
  final String? description;

  PermissionModel({
    required this.id,
    required this.permissionName,
    this.description,
  });

  factory PermissionModel.fromMap(Map<String, dynamic> map) {
    return PermissionModel(
      id: map['id'],
      permissionName: map['permission_name'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'permission_name': permissionName,
      'description': description,
    };
  }
}
