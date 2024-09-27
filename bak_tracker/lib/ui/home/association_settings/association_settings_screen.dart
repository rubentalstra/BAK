import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/ui/home/approve_baks/approve_baks_screen.dart';
import 'package:bak_tracker/ui/home/association_settings/invite_members_screen.dart';
import 'package:bak_tracker/ui/home/association_settings/remove_members_screen.dart';
import 'package:bak_tracker/ui/home/association_settings/permissions/list_permissions_screen.dart';
import 'package:bak_tracker/ui/home/association_settings/update_roles_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AssociationSettingsScreen extends StatelessWidget {
  final AssociationMemberModel memberData;
  final String associationId;
  final AssociationService associationService = AssociationService();

  AssociationSettingsScreen({
    super.key,
    required this.memberData,
    required this.associationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Association Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Show Invite Members option if the user has permission
          _buildOptionTile(
            context,
            icon: Icons.group_add,
            title: 'Invite Members',
            subtitle: 'Send invites to new members',
            onTap: memberData.canInviteMembers
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => InviteMembersScreen(
                          associationId: associationId,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          if (memberData.canInviteMembers) const Divider(),

          // Show Remove Members option if the user has permission
          _buildOptionTile(
            context,
            icon: Icons.person_remove,
            title: 'Remove Members',
            subtitle: 'Remove members from the association',
            onTap: memberData.canRemoveMembers
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RemoveMembersScreen(
                          associationId: associationId,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          if (memberData.canRemoveMembers) const Divider(),

          // Show Manage Permissions option if the user has permission
          _buildOptionTile(
            context,
            icon: Icons.admin_panel_settings,
            title: 'Manage Permissions',
            subtitle: 'Update member permissions',
            onTap: memberData.canManagePermissions
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UpdatePermissionsScreen(
                          associationId: associationId,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          if (memberData.canManagePermissions) const Divider(),

          // Show Manage Roles option if the user has permission
          _buildOptionTile(
            context,
            icon: Icons.assignment_ind,
            title: 'Manage Roles',
            subtitle: 'Update member roles',
            onTap: memberData.canManageRoles
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UpdateRolesScreen(
                          associationId: associationId,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          if (memberData.canManageRoles) const Divider(),

          // Show Approve Baks option if the user has permission
          _buildOptionTile(
            context,
            icon: FontAwesomeIcons.circleCheck,
            title: 'Approve Baks',
            subtitle: 'Approve or reject pending baks',
            onTap: memberData.canApproveBaks
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ApproveBaksScreen(),
                      ),
                    );
                  }
                : null,
          ),
          if (memberData.canApproveBaks) const Divider(),

          // Show Reset Bak Amount option if the user has permission
          _buildOptionTile(
            context,
            icon: Icons.restore,
            title: 'Reset Bak Amount',
            subtitle: 'Reset the amount of baks received and consumed',
            titleStyle: TextStyle(color: Colors.red.shade500),
            onTap: memberData.canManageBaks
                ? () => _showResetBakDialog(context)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    TextStyle? titleStyle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.lightSecondary),
      title: Text(title,
          style: titleStyle ?? const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showResetBakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Bak Amount'),
          content: const Text(
              'Are you sure you want to reset all BAKs consumed and received? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.lightSecondary)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Call the reset method
                  await associationService.resetAllBaks(associationId);

                  // Show success SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('BAKs have been reset successfully'),
                    ),
                  );
                } catch (e) {
                  // Show error SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                    ),
                  );
                }

                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
