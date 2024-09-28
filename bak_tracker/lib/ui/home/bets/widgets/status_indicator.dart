import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    if (status == 'pending') {
      statusColor = Colors.orange;
      statusText = 'Pending Approval';
    } else if (status == 'accepted') {
      statusColor = Colors.green;
      statusText = 'Accepted - Ready to Settle';
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown Status';
    }

    return Row(
      children: [
        Icon(
          Icons.circle,
          color: statusColor,
          size: 12,
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}
