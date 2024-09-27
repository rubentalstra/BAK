import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoveMembersScreen extends StatefulWidget {
  final String associationId;

  const RemoveMembersScreen({super.key, required this.associationId});

  @override
  _RemoveMembersScreenState createState() => _RemoveMembersScreenState();
}

class _RemoveMembersScreenState extends State<RemoveMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _getCurrentUserId();
  }

  // Fetch the logged-in user's ID
  Future<void> _getCurrentUserId() async {
    final supabase = Supabase.instance.client;
    setState(() {
      _currentUserId = supabase.auth.currentUser?.id;
    });
  }

  // Fetch association members from Supabase
  Future<void> _fetchMembers() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('association_members')
          .select('user_id (id, name), role, permissions')
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

  // Remove a member from the association
  Future<void> _removeMember(String userId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('association_members')
          .delete()
          .eq('user_id', userId)
          .eq('association_id', widget.associationId);
      _fetchMembers(); // Refresh the member list
    } catch (e) {
      print('Error removing member: $e');
    }
  }

  // Show confirmation dialog
  Future<void> _confirmRemoveMember(BuildContext context, String userId,
      String memberName, bool hasAllPermissions) async {
    if (hasAllPermissions) {
      // Show message for members with full permissions
      _showCannotRemoveDialog(context, memberName);
    } else {
      final bool? shouldRemove = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Removal'),
            content: Text('Are you sure you want to remove $memberName?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Cancel
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Confirm
                child:
                    const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );

      if (shouldRemove == true) {
        // If confirmed, remove the member
        _removeMember(userId);
      }
    }
  }

  // Show a dialog when a member with full permissions cannot be removed
  Future<void> _showCannotRemoveDialog(
      BuildContext context, String memberName) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cannot Remove Member'),
          content:
              Text('$memberName has full permissions and cannot be removed. '
                  'Please downgrade their role first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Build list tile for each member
  Widget _buildMemberTile(Map<String, dynamic> member) {
    final memberId = member['user_id']['id'];
    final memberName = member['user_id']['name'];
    final hasAllPermissions =
        member['permissions']['hasAllPermissions'] ?? false;
    final isCurrentUser = memberId == _currentUserId;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hasAllPermissions ? Colors.blue : Colors.grey,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        memberName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            member['role'],
            style: TextStyle(
              color: Colors.grey.shade300,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Permissions: ${hasAllPermissions ? "Full Access" : _formatPermissions(member['permissions'])}',
            style: TextStyle(
              color: hasAllPermissions ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
      trailing: isCurrentUser
          ? const IconButton(
              icon: Icon(Icons.block, color: Colors.grey),
              tooltip: 'You cannot remove yourself',
              onPressed: null,
            )
          : hasAllPermissions
              ? const IconButton(
                  icon: Icon(Icons.lock, color: Colors.red),
                  tooltip:
                      'This member has full permissions and cannot be removed',
                  onPressed: null,
                )
              : IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: () => _confirmRemoveMember(
                    context,
                    memberId,
                    memberName,
                    hasAllPermissions,
                  ),
                ),
    );
  }

  // Function to format the permissions for display
  String _formatPermissions(Map<String, dynamic> permissions) {
    final permissionList = [];
    if (permissions['canInviteMembers'] ?? false) permissionList.add('Invite');
    if (permissions['canRemoveMembers'] ?? false) permissionList.add('Remove');
    if (permissions['canManagePermissions'] ?? false) {
      permissionList.add('Manage Permissions');
    }
    if (permissions['canManageRoles'] ?? false) {
      permissionList.add('Manage Roles');
    }
    if (permissions['canApproveBaks'] ?? false) {
      permissionList.add('Approve Baks');
    }
    return permissionList.isEmpty
        ? 'No Special Permissions'
        : permissionList.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Members'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(child: Text('No members to display'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildMemberTile(member),
                    );
                  },
                ),
    );
  }
}
