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

  @override
  void initState() {
    super.initState();
    // Initialize with all possible permissions, using current values
    _permissions = {
      'invite_members': widget.currentPermissions['invite_members'] ?? false,
      'remove_members': widget.currentPermissions['remove_members'] ?? false,
      'update_role': widget.currentPermissions['update_role'] ?? false,
      'update_bak_amount':
          widget.currentPermissions['update_bak_amount'] ?? false,
      'approve_bak_taken':
          widget.currentPermissions['approve_bak_taken'] ?? false,
      'update_permissions':
          widget.currentPermissions['update_permissions'] ?? false,
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
                  _buildPermissionSwitch('Invite Members', 'invite_members'),
                  _buildPermissionSwitch('Remove Members', 'remove_members'),
                  _buildPermissionSwitch('Update Role', 'update_role'),
                  _buildPermissionSwitch(
                      'Update Bak Amount', 'update_bak_amount'),
                  _buildPermissionSwitch(
                      'Approve Bak Taken', 'approve_bak_taken'),
                  _buildPermissionSwitch(
                      'Update Permissions', 'update_permissions'),
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

  // Helper method to build each permission switch
  Widget _buildPermissionSwitch(String label, String permissionKey) {
    return SwitchListTile(
      title: Text(label),
      activeTrackColor: AppColors.lightSecondary,
      value: _permissions[permissionKey] ?? false,
      onChanged: (bool value) {
        setState(() {
          _permissions[permissionKey] = value;
        });
      },
    );
  }
}
