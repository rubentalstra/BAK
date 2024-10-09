import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/widgets/profile_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/core/const/permissions_constants.dart';

class RemoveMembersScreen extends StatefulWidget {
  final String associationId;
  final ImageUploadService imageUploadService;

  const RemoveMembersScreen(
      {super.key,
      required this.associationId,
      required this.imageUploadService});

  @override
  _RemoveMembersScreenState createState() => _RemoveMembersScreenState();
}

class _RemoveMembersScreenState extends State<RemoveMembersScreen> {
  List<AssociationMemberModel> _members = [];
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
          .select(
              'id, association_id, joined_at, user_id (id, name, bio, profile_image), role, permissions, member_achievements (id, assigned_at, achievement_id(id, name, description, created_at))')
          .eq('association_id', widget.associationId);

      setState(() {
        _members = List<AssociationMemberModel>.from(
          response.map((data) {
            return AssociationMemberModel.fromMap(data);
          }),
        );
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
      String memberName, PermissionsModel permissions) async {
    if (permissions.hasPermission(PermissionEnum.hasAllPermissions)) {
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

  // Build list tile for each member using ProfileImageWidget
  Widget _buildMemberTile(AssociationMemberModel member) {
    final memberId = member.user.id;
    final memberName = member.user.name;
    final hasAllPermissions =
        member.permissions.hasPermission(PermissionEnum.hasAllPermissions);
    final isCurrentUser = memberId == _currentUserId;

    return ListTile(
      leading: ProfileImageWidget(
        profileImageUrl: member.user.profileImage,
        userName: member.user.name,
        fetchProfileImage:
            widget.imageUploadService.fetchOrDownloadProfileImage,
        radius: 24.0, // Set the profile image size
        backgroundColor: hasAllPermissions
            ? Colors.blue
            : Colors.grey, // Color based on permissions
      ),
      title: Text(
        memberName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            member.role ?? '',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Permissions: ${hasAllPermissions ? "Full Access" : _formatPermissions(member.permissions)}',
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
                    member.permissions,
                  ),
                ),
    );
  }

  // Function to format the permissions for display
  String _formatPermissions(PermissionsModel permissions) {
    final permissionList = PermissionEnum.values
        .where((permission) => permissions.hasPermission(permission))
        .map((permission) => permission
            .toString()
            .split('.')
            .last
            .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
            .trim())
        .toList();

    return permissionList.isEmpty
        ? 'No Special Permissions'
        : permissionList.join(', ');
  }

  // Pull to refresh functionality
  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchMembers(); // Fetch members again
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
              : RefreshIndicator(
                  color: AppColors.lightSecondary,
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
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
                ),
    );
  }
}
