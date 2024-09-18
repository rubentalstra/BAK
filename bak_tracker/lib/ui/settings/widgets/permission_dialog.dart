import 'package:flutter/material.dart';

class PermissionDialog extends StatefulWidget {
  final Map<String, dynamic> currentPermissions;

  const PermissionDialog({super.key, required this.currentPermissions});

  @override
  _PermissionDialogState createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  late Map<String, bool> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = Map<String, bool>.from(widget.currentPermissions
        .map((key, value) => MapEntry(key, value as bool)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Permissions'),
      content: SingleChildScrollView(
        child: Column(
          children: _permissions.keys.map((key) {
            return SwitchListTile(
              title: Text(_getPermissionLabel(key)),
              value: _permissions[key] ?? false,
              onChanged: (bool value) {
                setState(() {
                  _permissions[key] = value;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _permissions),
          child: const Text('Update'),
        ),
      ],
    );
  }

  String _getPermissionLabel(String permissionKey) {
    switch (permissionKey) {
      case 'invite_members':
        return 'Invite Members';
      case 'remove_members':
        return 'Remove Members';
      case 'update_role':
        return 'Update Role';
      case 'update_bak_amount':
        return 'Update Bak Amount';
      case 'approve_bak_taken':
        return 'Approve Bak Taken';
      case 'update_permissions':
        return 'Update Permissions';
      default:
        return permissionKey; // Default to key if no label found
    }
  }
}
