import 'package:bak_tracker/models/invite_model.dart';
import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ActiveInvitesTab extends StatelessWidget {
  final List<InviteModel> invites;
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

    return ListView.builder(
      itemCount: invites.length,
      itemBuilder: (context, index) {
        final invite = invites[index];
        final inviteKey = invite.inviteKey;

        final Duration? timeUntilExpiration =
            invite.expiresAt?.difference(DateTime.now());

        // Format expiration dates for display
        final String expirationDateTime = invite.expiresAt != null
            ? DateFormat('dd-MM-yyyy HH:mm').format(invite.expiresAt!)
            : 'No expiration';

        String expirationDisplay = 'No expiration';
        if (timeUntilExpiration != null) {
          if (timeUntilExpiration.inDays > 0) {
            expirationDisplay = '${timeUntilExpiration.inDays} days left';
          } else if (timeUntilExpiration.inDays == 0) {
            expirationDisplay = 'Expires today';
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0, vertical: 8.0), // Match padding
          child: Card(
            elevation: 1, // Match elevation
            margin: EdgeInsets.zero, // Remove default card margin
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Match radius
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(12), // Match padding inside card
              leading: CircleAvatar(
                backgroundColor: Colors.greenAccent.withOpacity(0.1),
                radius: 24,
                child: const Icon(
                  FontAwesomeIcons.key,
                  color: Colors.greenAccent,
                ),
              ),
              title: Text(
                'Invite Key: $inviteKey',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(
                    top: 4.0), // Match padding between elements
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.calendarDay,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created: ${DateFormat('dd-MM-yyyy').format(invite.createdAt)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.hourglassEnd,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              expirationDisplay, // Expiration status
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4), // Add space between rows
                        Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.clock,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              expirationDateTime, // Expiration date and time
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildPermissionsSummary(invite.permissions),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String result) {
                  switch (result) {
                    case 'Copy':
                      onCopyInviteKey(inviteKey);
                      break;
                    case 'Share':
                      onShareInvite(inviteKey);
                      break;
                    case 'Expire':
                      onExpireInvite(invite.id);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Copy',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Copy Invite Key'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Share',
                    child: ListTile(
                      leading: FaIcon(FontAwesomeIcons.shareFromSquare),
                      title: Text('Share Invite'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Expire',
                    child: ListTile(
                      leading: Icon(Icons.cancel),
                      title: Text('Expire Invite'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build a summary of current permissions using the new method
  String _buildPermissionsSummary(Map<String, dynamic> permissions) {
    List<String> permissionLabels = [];

    if (permissions['hasAllPermissions'] == true) {
      permissionLabels.add('Has All Permissions');
    } else {
      for (var permission in PermissionEnum.values) {
        if (permissions[permission.toString().split('.').last] == true) {
          permissionLabels.add(permission
              .toString()
              .split('.')
              .last
              .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
              .trim());
        }
      }
    }

    return permissionLabels.isNotEmpty
        ? permissionLabels.join(', ')
        : 'No Permissions';
  }
}
