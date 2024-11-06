import 'package:bak_tracker/models/invite_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ExpiredInvitesTab extends StatelessWidget {
  final List<InviteModel> invites;
  final Function(String) onDeleteInvite; // Add a callback for deleting invites

  const ExpiredInvitesTab({
    super.key,
    required this.invites,
    required this.onDeleteInvite, // Pass the callback
  });

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) {
      return const Center(
        child: Text(
          'No expired invites.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: invites.length,
      itemBuilder: (context, index) {
        final invite = invites[index];

        final DateTime createdAt = invite.createdAt;
        final DateTime? expiresAt = invite.expiresAt;

        // Format dates for display
        final String createdDate = DateFormat('dd-MM-yyyy').format(createdAt);
        final String expirationDisplay = expiresAt != null
            ? 'Expired on ${DateFormat('dd-MM-yyyy').format(expiresAt)}'
            : 'No expiration';

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.all(12), // Match padding inside card
              leading: CircleAvatar(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                radius: 24,
                child: const Icon(
                  FontAwesomeIcons.clock,
                  color: Colors.redAccent,
                ),
              ),
              title: Text(
                'Invite Key: ${invite.inviteKey}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0), // Match padding
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
                          'Created: $createdDate',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), // Match space between rows
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.hourglassEnd,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          expirationDisplay,
                          style: TextStyle(
                            color: expiresAt != null
                                ? Colors.redAccent
                                : Colors.grey,
                            fontWeight: expiresAt != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: 'Delete Invite',
                onPressed: () => _showDeleteConfirmation(
                    context, invite.id), // Trigger the delete action
              ),
            ),
          ),
        );
      },
    );
  }

  // Function to show a confirmation dialog before deleting
  void _showDeleteConfirmation(BuildContext context, String inviteId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Invite'),
          content: const Text('Are you sure you want to delete this invite?'),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onDeleteInvite(inviteId); // Invoke the delete action
              },
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
