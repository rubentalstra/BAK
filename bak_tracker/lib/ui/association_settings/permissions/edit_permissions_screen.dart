import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPermissionsScreen extends StatefulWidget {
  final String memberId;
  final String associationId;
  final PermissionsModel currentPermissions; // Change to use PermissionsModel

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
  late PermissionsModel _permissions; // Use PermissionsModel
  bool _isSaving = false;

  // Grouping permissions for better UI organization
  final List<Map<String, dynamic>> _permissionGroups = [
    {
      'groupName': 'All Permissions',
      'permissions': [PermissionEnum.hasAllPermissions],
    },
    {
      'groupName': 'Specific Permissions',
      'permissions': [
        PermissionEnum.canManagePermissions,
        PermissionEnum.canInviteMembers,
        PermissionEnum.canRemoveMembers,
        PermissionEnum.canManageRoles,
        PermissionEnum.canManageBaks,
        PermissionEnum.canApproveBaks,
        PermissionEnum.canManageAchievements,
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  // Initialize the permissions model based on current permissions
  void _initializePermissions() {
    _permissions = widget.currentPermissions;
  }

  // Save the updated permissions to Supabase
  Future<void> _savePermissions() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('association_members')
          .update({'permissions': _permissions.toMap()})
          .eq('user_id', widget.memberId)
          .eq('association_id', widget.associationId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions updated successfully')),
      );
      Navigator.of(context).pop(); // Close the screen after saving
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

  // Update the permissions model when a switch is toggled
  void _updatePermission(PermissionEnum permission, bool value) {
    setState(() {
      _permissions.updatePermission(permission, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build the permission groups
    final List<Widget> permissionGroups = _permissionGroups.map((group) {
      return _buildPermissionGroup(
        groupName: group['groupName'],
        permissionEnums: List<PermissionEnum>.from(group['permissions']),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Permissions'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Adjust Member Permissions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: permissionGroups,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _savePermissions,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Save Permissions'),
                  ),
                ],
              ),
            ),
    );
  }

  // Build each permission group with its switches
  Widget _buildPermissionGroup({
    required String groupName,
    required List<PermissionEnum> permissionEnums,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.lightPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...permissionEnums.map((permission) {
          return _buildPermissionSwitch(
            label: permission.label,
            permissionKey: permission,
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  // Build each permission switch
  Widget _buildPermissionSwitch({
    required String label,
    required PermissionEnum permissionKey,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: SwitchListTile(
        title: Text(label),
        // activeColor: AppColors.lightSecondary,
        value: _permissions.permissions[permissionKey] ?? false,
        onChanged: (bool value) {
          _updatePermission(permissionKey, value);
        },
      ),
    );
  }
}
