import 'package:flutter/material.dart';

class PendingActions extends StatelessWidget {
  final Map<String, dynamic> bet;
  final Function(String, String, String) onUpdateBetStatus;

  const PendingActions({
    super.key,
    required this.bet,
    required this.onUpdateBetStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => onUpdateBetStatus(
              bet['id'], 'accepted', bet['bet_creator_id']['id']),
          child: const Text(
            'Accept',
            style: TextStyle(color: Colors.green),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => onUpdateBetStatus(
              bet['id'], 'rejected', bet['bet_creator_id']['id']),
          child: const Text(
            'Reject',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
