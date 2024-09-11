import 'package:flutter/material.dart';

class PendingApprovalsScreen extends StatelessWidget {
  const PendingApprovalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pending Bakken Approvals'),
            // Add list of pending approvals
          ],
        ),
      ),
    );
  }
}
