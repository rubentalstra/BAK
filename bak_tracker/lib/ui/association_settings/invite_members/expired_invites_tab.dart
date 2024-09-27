import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpiredInvitesTab extends StatelessWidget {
  final List<Map<String, dynamic>> invites;

  const ExpiredInvitesTab({
    super.key,
    required this.invites,
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

    return ListView.separated(
      itemCount: invites.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final invite = invites[index];
        final inviteKey = invite['invite_key'];

        final DateTime createdAt = DateTime.parse(invite['created_at']);
        final DateTime? expiresAt = invite['expires_at'] != null
            ? DateTime.parse(invite['expires_at'])
            : null;

        // Format dates for display
        final String createdDate = DateFormat('dd-MM-yyyy').format(createdAt);
        final String expirationDisplay = expiresAt != null
            ? 'Expired on ${DateFormat('dd-MM-yyyy').format(expiresAt)}'
            : 'No expiration';

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
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }
}
