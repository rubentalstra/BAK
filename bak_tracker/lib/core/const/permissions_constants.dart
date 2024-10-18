enum PermissionEnum {
  hasAllPermissions,
  canManagePermissions,
  canInviteMembers,
  canRemoveMembers,
  canManageRoles,
  canManageBaks,
  canApproveBaks,
  canManageAchievements,
  canManageRegulations,
}

// Extension to provide labels for permissions
extension PermissionEnumLabel on PermissionEnum {
  String get label {
    switch (this) {
      case PermissionEnum.hasAllPermissions:
        return 'Has All Permissions';
      case PermissionEnum.canManagePermissions:
        return 'Manage Permissions';
      case PermissionEnum.canInviteMembers:
        return 'Invite Members';
      case PermissionEnum.canRemoveMembers:
        return 'Remove Members';
      case PermissionEnum.canManageRoles:
        return 'Manage Roles';
      case PermissionEnum.canManageBaks:
        return 'Manage Baks';
      case PermissionEnum.canApproveBaks:
        return 'Approve Baks';
      case PermissionEnum.canManageAchievements:
        return 'Manage Achievements';
      case PermissionEnum.canManageRegulations:
        return 'Manage Regulations';
      default:
        return '';
    }
  }
}

class PermissionsModel {
  final Map<PermissionEnum, bool> permissions;

  PermissionsModel({Map<PermissionEnum, bool>? permissions})
      : permissions = permissions ?? _getDefaultPermissions();

  static Map<PermissionEnum, bool> _getDefaultPermissions() {
    return {
      for (var permission in PermissionEnum.values) permission: false,
    };
  }

  factory PermissionsModel.fromMap(Map<String, dynamic> map) {
    final permissions =
        _getDefaultPermissions(); // Initialize with default permissions

    // Map the permissions from the provided map
    map.forEach((key, value) {
      try {
        final permission = PermissionEnum.values
            .firstWhere((e) => e.toString() == 'PermissionEnum.$key');
        permissions[permission] = value ?? false; // Set the mapped value
      } catch (e) {
        // If the permission key is not recognized, it will remain false
        print('Unrecognized permission key: $key');
      }
    });

    return PermissionsModel(permissions: permissions);
  }

  Map<String, dynamic> toMap() {
    return permissions
        .map((key, value) => MapEntry(key.toString().split('.').last, value));
  }

  bool hasPermission(PermissionEnum permission) {
    return permissions[PermissionEnum.hasAllPermissions] == true ||
        permissions[permission] == true;
  }

  void updatePermission(PermissionEnum permission, bool value) {
    if (permission == PermissionEnum.hasAllPermissions) {
      // When setting hasAllPermissions, reset all others to false
      for (var key in PermissionEnum.values) {
        if (key != PermissionEnum.hasAllPermissions) {
          permissions[key] = false;
        }
      }
    } else {
      // If any permission is set to true, ensure hasAllPermissions is false
      if (value) {
        permissions[PermissionEnum.hasAllPermissions] = false;
      }
    }
    permissions[permission] = value;
  }
}
