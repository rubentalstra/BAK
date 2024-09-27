import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPermissionsScreen extends StatefulWidget {
  final String memberId;
  final String associationId;
  final Map<String, dynamic> currentPermissions;

  const EditPermissionsScreen({
    super.key,
    required this.memberId,
    required this.associationId,
    required this.currentPermissions,
  });

  @override
  _EditPermissionsScreenState createState() => _EditPermissionsScreenState();
}

class _EditPermissionsScreenState extends State<EditPermissionsScreen> {
  late Map<String, bool> _permissions;
  bool _isSaving = false;

  final Map<String, String> _permissionLabels = {
    'hasAllPermissions': 'Has All Permissions',
    'canManagePermissions': 'Manage Permissions',
    'canInviteMembers': 'Invite Members',
    'canRemoveMembers': 'Remove Members',
    'canManageRoles': 'Manage Roles',
    'canManageBaks': 'Manage Baks',
    'canApproveBaks': 'Approve Baks',
  };

  @override
  void initState() {
    super.initState();
    _permissions = {
      'hasAllPermissions':
          widget.currentPermissions['hasAllPermissions'] ?? false,
      'canManagePermissions':
          widget.currentPermissions['canManagePermissions'] ?? false,
      'canInviteMembers':
          widget.currentPermissions['canInviteMembers'] ?? false,
      'canRemoveMembers':
          widget.currentPermissions['canRemoveMembers'] ?? false,
      'canManageRoles': widget.currentPermissions['canManageRoles'] ?? false,
      'canManageBaks': widget.currentPermissions['canManageBaks'] ?? false,
      'canApproveBaks': widget.currentPermissions['canApproveBaks'] ?? false,
    };
  }

  Future<void> _savePermissions() async {
    final supabase = Supabase.instance.client;
    setState(() {
      _isSaving = true;
    });

    try {
      await supabase
          .from('association_members')
          .update({'permissions': _permissions})
          .eq('user_id', widget.memberId)
          .eq('association_id', widget.associationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      print('Error saving permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update permissions')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Permissions'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ..._permissionLabels.keys.map(
                    (key) => _buildPermissionSwitch(
                      _permissionLabels[key] ?? key,
                      key,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _savePermissions,
                    child: const Text('Save Permissions'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionSwitch(String label, String permissionKey) {
    return SwitchListTile(
      title: Text(label),
      activeTrackColor: AppColors.lightSecondary,
      value: _permissions[permissionKey] ?? false,
      onChanged: (bool value) {
        setState(() {
          if (permissionKey == 'hasAllPermissions') {
            _permissions = {
              'hasAllPermissions': value,
              'canManagePermissions': !value,
              'canInviteMembers': !value,
              'canRemoveMembers': !value,
              'canManageRoles': !value,
              'canManageBaks': !value,
              'canApproveBaks': !value,
            };
          } else {
            _permissions[permissionKey] = value;
            // Disable all if specific is enabled
            _permissions['hasAllPermissions'] = false;
          }
        });
      },
    );
  }
}
