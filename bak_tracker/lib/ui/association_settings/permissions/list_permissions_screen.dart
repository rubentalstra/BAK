import 'package:bak_tracker/ui/association_settings/permissions/edit_permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:bak_tracker/core/const/permissions_constants.dart';
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
          .eq('association_id', widget.associationId)
          .order('user_id(name)', ascending: true);

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
                padding: const EdgeInsets.all(8.0),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final permissions =
                      PermissionsModel.fromMap(member['permissions']);

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        member['user_id']['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _buildPermissionsSummary(permissions),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
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
                    ),
                  );
                },
              ),
            ),
    );
  }

  // Build a summary of current permissions
  String _buildPermissionsSummary(PermissionsModel permissions) {
    List<String> permissionLabels = [];

    // Check if the user has all permissions
    if (permissions.hasPermission(PermissionEnum.hasAllPermissions)) {
      permissionLabels.add('Has All Permissions');
    } else {
      for (var permission in PermissionEnum.values) {
        if (permissions.hasPermission(permission)) {
          permissionLabels.add(permission.label);
        }
      }
    }

    return permissionLabels.isNotEmpty
        ? permissionLabels.join(', ')
        : 'No Permissions';
  }
}
