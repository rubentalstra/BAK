import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateRolesScreen extends StatefulWidget {
  final String associationId;

  const UpdateRolesScreen({super.key, required this.associationId});

  @override
  _UpdateRolesScreenState createState() => _UpdateRolesScreenState();
}

class _UpdateRolesScreenState extends State<UpdateRolesScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  // Fetch association members from Supabase
  Future<void> _fetchMembers() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('association_members')
          .select('user_id (id, name), role')
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

  // Update the role for a specific user
  Future<void> _updateRole(String userId, String newRole) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('association_members')
          .update({'role': newRole})
          .eq('user_id', userId)
          .eq('association_id', widget.associationId);
      _fetchMembers(); // Refresh the member list
    } catch (e) {
      print('Error updating role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Roles'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return ListTile(
                  title: Text(member['user_id']['name']),
                  subtitle: Text('Current role: ${member['role']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newRole = await _showRoleDialog(member['role']);
                      if (newRole != null && newRole.isNotEmpty) {
                        _updateRole(member['user_id']['id'], newRole);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  // Dialog to update the role with the current role pre-filled
  Future<String?> _showRoleDialog(String currentRole) {
    final roleController = TextEditingController(
        text: currentRole); // Pre-fill the text field with the current role
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter new role'),
          content: TextField(
            controller: roleController,
            decoration: const InputDecoration(hintText: 'New role'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Cancel
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
                onPressed: () => Navigator.pop(
                    context, roleController.text), // Update with the new role
                child: const Text(
                  'Update',
                  style: TextStyle(color: AppColors.lightSecondary),
                )),
          ],
        );
      },
    );
  }
}
