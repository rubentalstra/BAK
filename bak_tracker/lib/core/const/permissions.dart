// permissions_constants.dart
const Map<String, bool> defaultPermissions = {
  'hasAllPermissions': false,
  'canManagePermissions': false,
  'canInviteMembers': false,
  'canRemoveMembers': false,
  'canManageRoles': false,
  'canManageBaks': false,
  'canApproveBaks': false,
  'canManageAchievements': false,
  // Add any other permissions here
};

// Utility function to check a specific permission in a permissions map
bool hasPermission(Map<String, dynamic> userPermissions, String permission) {
  return userPermissions[permission] ?? defaultPermissions[permission] ?? false;
}
