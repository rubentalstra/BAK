import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ActiveInvitesTab extends StatelessWidget {
  final List<Map<String, dynamic>> invites;
  final Function(String) onCopyInviteKey;
  final Function(String) onShareInvite;
  final Function(String) onExpireInvite;

  const ActiveInvitesTab({
    super.key,
    required this.invites,
    required this.onCopyInviteKey,
    required this.onShareInvite,
    required this.onExpireInvite,
  });

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) {
      return const Center(
        child: Text(
          'No active invites.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: invites.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final invite = invites[index];
        final inviteKey = invite['invite_key'];
        final inviteId = invite['id'];

        final DateTime createdAt = DateTime.parse(invite['created_at']);
        final DateTime? expiresAt = invite['expires_at'] != null
            ? DateTime.parse(invite['expires_at'])
            : null;

        // Calculate remaining time until expiration
        final Duration? timeUntilExpiration =
            expiresAt?.difference(DateTime.now());

        // Format dates for display
        final String createdDate = DateFormat('dd-MM-yyyy').format(createdAt);
        String expirationDisplay = 'No expiration';
        if (expiresAt != null) {
          if (timeUntilExpiration != null && timeUntilExpiration.inDays > 0) {
            expirationDisplay =
                '${timeUntilExpiration.inDays} days left (${DateFormat('dd-MM-yyyy').format(expiresAt)})';
          } else if (timeUntilExpiration != null &&
              timeUntilExpiration.inDays == 0) {
            expirationDisplay =
                'Expires today (${DateFormat('dd-MM-yyyy').format(expiresAt)})';
          } else {
            expirationDisplay =
                'Expired on ${DateFormat('dd-MM-yyyy').format(expiresAt)}';
          }
        }

        final permissions = Map<String, dynamic>.from(invite['permissions']);

        return ListTile(
          title: Text(
            'Invite Key: $inviteKey',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Created: $createdDate',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                expirationDisplay,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _buildPermissionsSummary(permissions),
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.copy),
                onPressed: () => onCopyInviteKey(inviteKey),
                tooltip: 'Copy Invite Key',
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.share),
                onPressed: () => onShareInvite(inviteKey),
                tooltip: 'Share Invite',
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.xmark),
                onPressed: () => onExpireInvite(inviteId),
                tooltip: 'Expire Invite',
              ),
            ],
          ),
        );
      },
    );
  }

  // Build a summary of permissions for display
  String _buildPermissionsSummary(Map<String, dynamic> permissions) {
    List<String> permissionLabels = [];

    if (permissions['hasAllPermissions'] == true) {
      permissionLabels.add('Has All Permissions');
    } else {
      if (permissions['canInviteMembers'] == true) {
        permissionLabels.add('Invite Members');
      }
      if (permissions['canRemoveMembers'] == true) {
        permissionLabels.add('Remove Members');
      }
      if (permissions['canManageRoles'] == true) {
        permissionLabels.add('Manage Roles');
      }
      if (permissions['canManageBaks'] == true) {
        permissionLabels.add('Manage Baks');
      }
      if (permissions['canApproveBaks'] == true) {
        permissionLabels.add('Approve Baks');
      }
      if (permissions['canManagePermissions'] == true) {
        permissionLabels.add('Manage Permissions');
      }
    }

    return permissionLabels.isNotEmpty
        ? permissionLabels.join(', ')
        : 'No Permissions';
  }
}
