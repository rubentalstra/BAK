import 'package:badges/badges.dart' as badges;
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/services/pdf_upload_service.dart';
import 'package:bak_tracker/ui/association_settings/achievements/achievement_screen.dart';
import 'package:bak_tracker/ui/association_settings/approve_baks/approve_baks_screen.dart';
import 'package:bak_tracker/ui/association_settings/invite_members/invite_members_screen.dart';
import 'package:bak_tracker/ui/association_settings/manage_regulations/manage_regulations_screen.dart';
import 'package:bak_tracker/ui/association_settings/permissions/list_permissions_screen.dart';
import 'package:bak_tracker/ui/association_settings/remove_members/remove_members_screen.dart';
import 'package:bak_tracker/ui/association_settings/roles/update_roles_screen.dart';
import 'package:bak_tracker/ui/association_settings/stats/manage_stats_screen.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      body: BlocListener<AssociationBloc, AssociationState>(
        listener: (context, state) {
          _handleAssociationStateChanges(context, state);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // User & Role Management Section
              if (_hasPermissionsForSection([
                PermissionEnum.canInviteMembers,
                PermissionEnum.canRemoveMembers,
                PermissionEnum.canManageRoles,
                PermissionEnum.canManagePermissions,
              ]))
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
                      imageUploadService: imageUploadService,
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
                      imageUploadService: imageUploadService,
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
              if (_hasPermissionsForSection([
                PermissionEnum.canManageAchievements,
                PermissionEnum.canApproveBaks,
                PermissionEnum.canManageBaks,
              ]))
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
                      imageUploadService: imageUploadService,
                    ),
                  ),
                ),
              ]),

              // Regulations & System Controls Section
              if (_hasPermissionsForSection([
                PermissionEnum.canManageRegulations,
                PermissionEnum.canManageBaks,
              ]))
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

              // Association Actions Section (always visible)
              _buildSectionHeader('Association Actions'),
              // View BAK Regulations Option
              _buildOptionTile(
                context,
                icon: FontAwesomeIcons.filePdf,
                title: 'View BAK Regulations',
                subtitle: 'Read the association\'s regulations',
                onTap: () => _handleViewAssociationPdf(context),
              ),
              _buildOptionTile(
                context,
                icon: FontAwesomeIcons.personWalkingArrowRight,
                title: 'Leave Association',
                subtitle: 'Leave the current association',
                titleStyle: TextStyle(color: Colors.red.shade600),
                onTap: () => _showConfirmLeaveDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to check if user has any permissions for a section
  bool _hasPermissionsForSection(List<PermissionEnum> permissions) {
    return permissions
        .any((permission) => memberData.hasPermission(permission));
  }

  // Method to handle association state changes
  void _handleAssociationStateChanges(
      BuildContext context, AssociationState state) {
    if (state is NoAssociationsLeft) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NoAssociationScreen()),
        (Route<dynamic> route) => false,
      );
    } else if (state is AssociationLeft || state is AssociationJoined) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } else if (state is AssociationLoaded && state.errorMessage != null) {
      _showErrorSnackBar(context, state.errorMessage!);
      context.read<AssociationBloc>().add(ClearAssociationError());
    } else if (state is AssociationError) {
      _showErrorSnackBar(context, state.message);
      context.read<AssociationBloc>().add(ClearAssociationError());
    }
  }

  // Method to show error SnackBar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // Handle viewing the association's PDF document
  void _handleViewAssociationPdf(BuildContext context) async {
    final pdfService = PDFUploadService(Supabase.instance.client);
    final pdfFileName = association.bakRegulations;
    final associationId = association.id;

    if (pdfFileName == null || pdfFileName.isEmpty) {
      _showErrorSnackBar(
          context, 'No Regulation uploaded for this association.');
      return;
    }

    try {
      final pdfFile =
          await pdfService.fetchOrDownloadPdf(pdfFileName, associationId);
      if (pdfFile != null) {
        await pdfService.openPdf(context, pdfFile);
      } else {
        _showErrorSnackBar(context, 'Failed to retrieve the PDF.');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'An error occurred while opening the PDF.');
    }
  }

  // Show the confirmation dialog for leaving the association
  void _showConfirmLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Association'),
          content: const Text(
              'Are you sure you want to leave the association? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.lightSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                // Dispatch the leave association event to the bloc
                context.read<AssociationBloc>().add(
                      LeaveAssociation(associationId: association.id),
                    );
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Leave',
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
