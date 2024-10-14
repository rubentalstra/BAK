import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/widgets/invite_code_input_widget.dart';
import '../settings/association_request_screen.dart';

class NoAssociationHomeScreen extends StatelessWidget {
  const NoAssociationHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join or Create Association'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Ensures full-width buttons
          children: [
            const Text(
              'You are not part of any association.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToAssociationRequest(context),
              child: const Text('Request Association'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _showInviteCodeInput(context),
              child: const Text('Join Association'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAssociationRequest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssociationRequestScreen(),
      ),
    );
  }

  void _showInviteCodeInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) => const InviteCodeInputWidget(),
    );
  }
}
