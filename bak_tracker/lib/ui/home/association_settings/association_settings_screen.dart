import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/ui/home/association_settings/invite_members_screen.dart';
import 'package:bak_tracker/ui/home/association_settings/remove_members_screen.dart';
import 'package:bak_tracker/ui/home/association_settings/permissions/list_permissions_screen.dart';
import 'package:bak_tracker/ui/home/association_settings/update_roles_screen.dart';
import 'package:flutter/material.dart';

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
          // Show Permissions option if the user has permission
          if (memberData.canInviteMembers)
            ListTile(
              title: const Text('Invite Members'),
              subtitle: const Text('Send invites to new members'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => InviteMembersScreen(
                      associationId: associationId,
                    ),
                  ),
                );
              },
            ),
          if (memberData.canInviteMembers) const Divider(),

          // Show Remove Members option if the user has permission
          if (memberData.canRemoveMembers)
            ListTile(
              title: const Text('Remove Members'),
              subtitle: const Text('Remove members from the association'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RemoveMembersScreen(
                      associationId: associationId,
                    ),
                  ),
                );
              },
            ),
          if (memberData.canRemoveMembers) const Divider(),

          // Show List Permissions option if the user has permission
          if (memberData.canManagePermissions)
            ListTile(
              title: const Text('Manage Permissions'),
              subtitle: const Text('Update member permissions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UpdatePermissionsScreen(
                      associationId: associationId,
                    ),
                  ),
                );
              },
            ),
          if (memberData.canManagePermissions) const Divider(),

          // Show Update Roles option if the user has permission
          if (memberData.canManageRoles)
            ListTile(
              title: const Text('Manage Roles'),
              subtitle: const Text('Update member roles'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UpdateRolesScreen(
                      associationId: associationId,
                    ),
                  ),
                );
              },
            ),
          if (memberData.canManageRoles) const Divider(),

          // show update bak amout option if the user has permission
          if (memberData.canManageBaks)
            ListTile(
              title: const Text('Update Bak Amount'),
              subtitle:
                  const Text('Update the amount of baks received and consumed'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => UpdateBakAmountScreen(
                //       associationId: associationId,
                //     ),
                //   ),
                // );
              },
            ),
          if (memberData.canManageBaks) const Divider(),

          // Show Reset Bak Amount option if the user has permission
          if (memberData.canManageBaks)
            ListTile(
              title: Text('Reset Bak Amount',
                  style: TextStyle(color: Colors.red.shade500)),
              subtitle:
                  const Text('Reset the amount of baks received and consumed'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
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
                            // Close the dialog without doing anything
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel',
                              style:
                                  TextStyle(color: AppColors.lightSecondary)),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              // Call the reset method
                              await associationService
                                  .resetAllBaks(associationId);

                              // Show success SnackBar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('BAKs have been reset successfully'),
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

                            // Close the dialog after the action
                            Navigator.of(context).pop();
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
              },
            ),
        ],
      ),
    );
  }
}
