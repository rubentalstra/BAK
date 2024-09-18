import 'package:bak_tracker/ui/settings/association_settings/permissions/edit_permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePermissionsScreen extends StatefulWidget {
  final String associationId;

  const UpdatePermissionsScreen({super.key, required this.associationId});

  @override
  _UpdatePermissionsScreenState createState() =>
      _UpdatePermissionsScreenState();
}

class _UpdatePermissionsScreenState extends State<UpdatePermissionsScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('association_members')
          .select('user_id (id, name), permissions')
          .eq('association_id', widget.associationId);

      setState(() {
        _members = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching members: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to refresh members list manually
  Future<void> _refreshMembers() async {
    await _fetchMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Permissions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshMembers, // Pull to refresh
              child: ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final permissions =
                      Map<String, dynamic>.from(member['permissions']);

                  return ListTile(
                    title: Text(member['user_id']['name']),
                    subtitle: Text(_buildPermissionsSummary(permissions)),
                    onTap: () async {
                      // Navigate to the EditPermissionsScreen and await result
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => EditPermissionsScreen(
                          memberId: member['user_id']['id'],
                          associationId: widget.associationId,
                          currentPermissions: permissions,
                        ),
                      ));
                      // Refresh the members list after returning from EditPermissionsScreen
                      _refreshMembers();
                    },
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
            ),
    );
  }

  // Build a summary of current permissions
  String _buildPermissionsSummary(Map<String, dynamic> permissions) {
    List<String> permissionLabels = [];

    if (permissions['invite_members'] == true) {
      permissionLabels.add('Invite Members');
    }
    if (permissions['remove_members'] == true) {
      permissionLabels.add('Remove Members');
    }
    if (permissions['update_role'] == true) {
      permissionLabels.add('Update Role');
    }
    if (permissions['update_bak_amount'] == true) {
      permissionLabels.add('Update Bak Amount');
    }
    if (permissions['approve_bak_taken'] == true) {
      permissionLabels.add('Approve Bak Taken');
    }
    if (permissions['update_permissions'] == true) {
      permissionLabels.add('Update Permissions');
    }

    return permissionLabels.isNotEmpty
        ? permissionLabels.join(', ')
        : 'No Permissions';
  }
}
