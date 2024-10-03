import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/ui/association_settings/achievements/achievement_screen.dart';
import 'package:bak_tracker/ui/association_settings/approve_baks/approve_baks_screen.dart';
import 'package:bak_tracker/ui/association_settings/invite_members/invite_members_screen.dart';
import 'package:bak_tracker/ui/association_settings/manage_regulations_screen.dart';
import 'package:bak_tracker/ui/association_settings/permissions/list_permissions_screen.dart';
import 'package:bak_tracker/ui/association_settings/remove_members_screen.dart';
import 'package:bak_tracker/ui/association_settings/update_roles_screen.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AssociationSettingsScreen extends StatelessWidget {
  final AssociationMemberModel memberData;
  final AssociationModel association;
  final AssociationService associationService = AssociationService();
  final int pendingAproveBaksCount; // Pass the pending baks count

  AssociationSettingsScreen({
    super.key,
    required this.memberData,
    required this.association,
    required this.pendingAproveBaksCount, // Required for badge
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Association Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: _buildOptions(context),
      ),
    );
  }

  List<Widget> _buildOptions(BuildContext context) {
    final options = <_AssociationOption>[
      _AssociationOption(
        condition: memberData.hasPermission(PermissionEnum.canInviteMembers),
        icon: Icons.group_add,
        title: 'Invite Members',
        subtitle: 'Send invites to new members',
        onTap: () => _navigateTo(
            context,
            InviteMembersScreen(
              associationId: association.id,
            )),
      ),
      _AssociationOption(
        condition: memberData.hasPermission(PermissionEnum.canRemoveMembers),
        icon: Icons.person_remove,
        title: 'Remove Members',
        subtitle: 'Remove members from the association',
        onTap: () => _navigateTo(
            context,
            RemoveMembersScreen(
              associationId: association.id,
            )),
      ),
      _AssociationOption(
        condition:
            memberData.hasPermission(PermissionEnum.canManagePermissions),
        icon: Icons.admin_panel_settings,
        title: 'Manage Permissions',
        subtitle: 'Update member permissions',
        onTap: () => _navigateTo(
            context,
            UpdatePermissionsScreen(
              associationId: association.id,
            )),
      ),
      _AssociationOption(
        condition: memberData.hasPermission(PermissionEnum.canManageRoles),
        icon: Icons.assignment_ind,
        title: 'Manage Roles',
        subtitle: 'Update member roles',
        onTap: () => _navigateTo(
            context,
            UpdateRolesScreen(
              associationId: association.id,
            )),
      ),
      _AssociationOption(
        condition:
            memberData.hasPermission(PermissionEnum.canManageAchievements),
        icon: FontAwesomeIcons.trophy,
        title: 'Manage Achievements',
        subtitle: 'Create and manage achievements',
        onTap: () => _navigateTo(
            context,
            AchievementManagementScreen(
              associationId: association.id,
            )),
      ),
      _AssociationOption(
        condition: memberData.hasPermission(PermissionEnum.canApproveBaks),
        icon: FontAwesomeIcons.circleCheck,
        title: 'Approve Baks',
        subtitle: 'Approve or reject pending baks',
        trailing: _buildBadge(),
        onTap: () => _navigateTo(
            context,
            ApproveBaksScreen(
              associationId: association.id,
            )),
      ),
      _AssociationOption(
        condition:
            memberData.hasPermission(PermissionEnum.canManageRegulations),
        icon: FontAwesomeIcons.filePdf,
        title: 'Association Regulations',
        subtitle: 'Manage association regulations',
        onTap: () => _navigateTo(context, ManageRegulationsScreen()),
      ),
      _AssociationOption(
        condition: memberData.hasPermission(PermissionEnum.canManageBaks),
        icon: Icons.restore,
        title: 'Reset Member Stats',
        subtitle:
            'Reset the baks received, baks consumed, bets won, and bets lost',
        titleStyle: TextStyle(color: Colors.red.shade500),
        onTap: () => _showResetBakDialog(context),
      ),
    ];

    return options
        .where(
            (option) => option.condition) // Filter options based on permissions
        .expand((option) => [
              _buildOptionTile(
                context,
                icon: option.icon,
                title: option.title,
                subtitle: option.subtitle,
                titleStyle: option.titleStyle,
                onTap: option.onTap,
                trailing: option.trailing,
              ),
              const Divider(), // Add a divider after each option
            ])
        .toList();
  }

  Widget _buildBadge() {
    return badges.Badge(
      showBadge: pendingAproveBaksCount > 0,
      badgeContent: Text(
        pendingAproveBaksCount.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: Colors.red,
      ),
      child: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    TextStyle? titleStyle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.lightSecondary),
      title: Text(
        title,
        style: titleStyle ?? const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showResetBakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Member Stats'),
          content: const Text(
              'Are you sure you want to reset the following stats for all members? This action cannot be undone:\n\n'
              '- Baks Received: 0\n'
              '- Baks Consumed: 0\n'
              '- Bets Won: 0\n'
              '- Bets Lost: 0\n\n'
              'Once reset, these values will be cleared for all members of the association.'),
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
                  await associationService.resetAllStats(association.id);

                  // Show success SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Member stats have been reset successfully'),
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

class _AssociationOption {
  final bool condition;
  final IconData icon;
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final VoidCallback? onTap;
  final Widget? trailing;

  _AssociationOption({
    required this.condition,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleStyle,
    this.onTap,
    this.trailing,
  });
}
