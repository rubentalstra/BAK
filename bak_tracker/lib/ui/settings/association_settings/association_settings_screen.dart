import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/ui/settings/association_settings/invite_members_screen.dart';
import 'package:bak_tracker/ui/settings/association_settings/remove_members_screen.dart';
import 'package:bak_tracker/ui/settings/association_settings/permissions/list_permissions_screen.dart';
import 'package:bak_tracker/ui/settings/association_settings/update_roles_screen.dart';
import 'package:flutter/material.dart';

class AssociationSettingsScreen extends StatelessWidget {
  final AssociationMemberModel memberData;
  final String associationId;

  const AssociationSettingsScreen({
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
          if (memberData.canInviteMembers)
            ListTile(
              title: const Text('Invite Members'),
              subtitle: const Text('Send invites to new members'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to invite members screen, passing associationId
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        InviteMembersScreen(associationId: associationId),
                  ),
                );
              },
            ),
          const Divider(),

          // Show Remove Members option if the user has permission
          if (memberData.canRemoveMembers)
            ListTile(
              title: const Text('Remove Members'),
              subtitle: const Text('Remove members from the association'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to remove members screen, passing associationId
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        RemoveMembersScreen(associationId: associationId),
                  ),
                );
              },
            ),
          const Divider(),

          // Show Permission option if the user has permission
          if (memberData.canUpdatePermissions)
            ListTile(
              title: const Text('Update Permissions'),
              subtitle: const Text('Update member permissions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdatePermissionsScreen(associationId: associationId),
                  ),
                );
              },
            ),
          const Divider(),

          // Show Update Role option if the user has permission
          if (memberData.canUpdateRole)
            ListTile(
              title: const Text('Update Roles'),
              subtitle: const Text('Manage member roles'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to update role screen, passing associationId
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdateRolesScreen(associationId: associationId),
                  ),
                );
              },
            ),
          const Divider(),

          // Show Update Bak Amount option if the user has permission
          if (memberData.canUpdateBakAmount)
            ListTile(
              title: const Text('Update Bak Amount'),
              subtitle: const Text('Update the amount of baks consumed'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to update bak amount screen, passing associationId
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => UpdateBakAmountScreen(associationId: associationId),
                //   ),
                // );
              },
            ),
          const Divider(),

          // Show Approve Bak Taken option if the user has permission
          if (memberData.canApproveBakTaken)
            ListTile(
              title: const Text('Approve Bak Taken'),
              subtitle: const Text('Approve baks that were consumed'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to approve baks screen, passing associationId
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => ApproveBaksScreen(associationId: associationId),
                //   ),
                // );
              },
            ),
        ],
      ),
    );
  }
}
