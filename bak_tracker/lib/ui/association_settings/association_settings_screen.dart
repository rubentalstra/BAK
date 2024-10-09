import 'package:badges/badges.dart' as badges;
import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/association_settings/achievements/achievement_screen.dart';
import 'package:bak_tracker/ui/association_settings/approve_baks/approve_baks_screen.dart';
import 'package:bak_tracker/ui/association_settings/invite_members/invite_members_screen.dart';
import 'package:bak_tracker/ui/association_settings/manage_regulations/manage_regulations_screen.dart';
import 'package:bak_tracker/ui/association_settings/permissions/list_permissions_screen.dart';
import 'package:bak_tracker/ui/association_settings/remove_members/remove_members_screen.dart';
import 'package:bak_tracker/ui/association_settings/roles/update_roles_screen.dart';
import 'package:bak_tracker/ui/association_settings/stats/manage_stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationSettingsScreen extends StatelessWidget {
  final AssociationMemberModel memberData;
  final AssociationModel association;
  final AssociationService associationService;
  final ImageUploadService imageUploadService; // Pass ImageUploadService
  final int pendingApproveBaksCount;

  AssociationSettingsScreen({
    super.key,
    required this.memberData,
    required this.association,
    required this.pendingApproveBaksCount,
    required this.imageUploadService, // Add this parameter
  }) : associationService = AssociationService(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Association Settings'),
        backgroundColor: AppColors.lightPrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // User & Role Management Section
            _buildSectionHeader('User & Role Management'),
            ..._buildOptions(context, [
              _AssociationOption(
                condition:
                    memberData.hasPermission(PermissionEnum.canInviteMembers),
                icon: FontAwesomeIcons.userPlus,
                title: 'Invite Members',
                subtitle: 'Send invites to new members',
                onTap: () => _navigateTo(
                  context,
                  InviteMembersScreen(associationId: association.id),
                ),
              ),
              _AssociationOption(
                condition:
                    memberData.hasPermission(PermissionEnum.canRemoveMembers),
                icon: FontAwesomeIcons.userMinus,
                title: 'Remove Members',
                subtitle: 'Remove members from the association',
                onTap: () => _navigateTo(
                  context,
                  RemoveMembersScreen(
                    associationId: association.id,
                    imageUploadService: imageUploadService, // Pass the service
                  ),
                ),
              ),
              _AssociationOption(
                condition:
                    memberData.hasPermission(PermissionEnum.canManageRoles),
                icon: FontAwesomeIcons.userTag,
                title: 'Manage Roles',
                subtitle: 'Update member roles',
                onTap: () => _navigateTo(
                  context,
                  UpdateRolesScreen(
                    associationId: association.id,
                    imageUploadService: imageUploadService, // Pass the service
                  ),
                ),
              ),
              _AssociationOption(
                condition: memberData
                    .hasPermission(PermissionEnum.canManagePermissions),
                icon: FontAwesomeIcons.userShield,
                title: 'Manage Permissions',
                subtitle: 'Update member permissions',
                onTap: () => _navigateTo(
                  context,
                  UpdatePermissionsScreen(
                    associationId: association.id,
                    imageUploadService: imageUploadService,
                  ),
                ),
              ),
            ]),

            // Achievements & Member Stats Section
            _buildSectionHeader('Achievements & Member Stats'),
            ..._buildOptions(context, [
              _AssociationOption(
                condition: memberData
                    .hasPermission(PermissionEnum.canManageAchievements),
                icon: FontAwesomeIcons.trophy,
                title: 'Manage Achievements',
                subtitle: 'Create and manage achievements',
                onTap: () => _navigateTo(
                  context,
                  AchievementManagementScreen(
                    associationId: association.id,
                    imageUploadService: imageUploadService,
                  ),
                ),
              ),
              _AssociationOption(
                condition:
                    memberData.hasPermission(PermissionEnum.canApproveBaks),
                icon: FontAwesomeIcons.circleCheck,
                title: 'Approve Baks',
                subtitle: 'Approve or reject pending baks',
                trailing: _buildBadge(),
                onTap: () => _navigateTo(
                  context,
                  ApproveBaksScreen(
                    associationId: association.id,
                    imageUploadService: imageUploadService,
                  ),
                ),
              ),
              _AssociationOption(
                condition:
                    memberData.hasPermission(PermissionEnum.canManageBaks),
                icon: FontAwesomeIcons.beerMugEmpty,
                title: 'Manage Member Stats',
                subtitle:
                    'Manually update baks and stats for individual members',
                onTap: () => _navigateTo(
                  context,
                  ManageStatsScreen(
                    associationId: association.id,
                    imageUploadService: imageUploadService, // Pass the service
                  ),
                ),
              ),
            ]),

            // Regulations & System Controls Section
            _buildSectionHeader('Regulations & System Controls'),
            ..._buildOptions(context, [
              _AssociationOption(
                condition: memberData
                    .hasPermission(PermissionEnum.canManageRegulations),
                icon: FontAwesomeIcons.fileLines,
                title: 'Association Regulations',
                subtitle: 'Manage association regulations',
                onTap: () => _navigateTo(context, ManageRegulationsScreen()),
              ),
              _AssociationOption(
                condition:
                    memberData.hasPermission(PermissionEnum.canManageBaks),
                icon: FontAwesomeIcons.arrowRotateRight,
                title: 'Reset Member Stats',
                subtitle: 'Reset the baks and stats for all members',
                titleStyle: TextStyle(color: Colors.red.shade600),
                onTap: () => _showResetBakDialog(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // Section Header Widget
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.lightSecondary,
        ),
      ),
    );
  }

  // List of options
  List<Widget> _buildOptions(
      BuildContext context, List<_AssociationOption> options) {
    return options
        .where((option) => option.condition)
        .map((option) => _buildOptionTile(
              context,
              icon: option.icon,
              title: option.title,
              subtitle: option.subtitle,
              titleStyle: option.titleStyle,
              onTap: option.onTap,
              trailing: option.trailing,
            ))
        .toList();
  }

  // Option Tile Builder
  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    TextStyle? titleStyle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.lightSecondary),
        title: Text(
          title,
          style: titleStyle ?? const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // Badge for the Approve Baks option
  Widget _buildBadge() {
    return badges.Badge(
      showBadge: pendingApproveBaksCount > 0,
      badgeContent: Text(
        pendingApproveBaksCount.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
      child: const Icon(Icons.chevron_right),
    );
  }

  // Navigation Helper
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Reset Bak Dialog
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.lightSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await associationService.resetAllStats(association.id);

                  // Show success SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Member stats have been reset successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                    ),
                  );
                }

                Navigator.of(context).pop();
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Association Option Data Class
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
