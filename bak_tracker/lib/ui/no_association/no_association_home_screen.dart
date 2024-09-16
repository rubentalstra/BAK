import 'package:bak_tracker/ui/widgets/invite_code_input_widget.dart';
import 'package:flutter/material.dart';
import 'association_request_screen.dart';

class NoAssociationHomeScreen extends StatelessWidget {
  const NoAssociationHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join or Create Association'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You are not part of any association.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AssociationRequestScreen()),
                );
              },
              child: const Text('Request Association'),
            ),
            ElevatedButton(
              onPressed: () {
                _showInviteCodeInput(context); // Show modal bottom sheet
              },
              child: const Text('Join Association'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show the InviteCodeInputWidget as a modal bottom sheet
  void _showInviteCodeInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Makes the bottom sheet take full height if needed
      builder: (BuildContext context) {
        return InviteCodeInputWidget(
          onCodeSubmitted: (String code) {
            _joinAssociationWithCode(context, code);
          },
        );
      },
    );
  }

  // Handle the code submission logic
  void _joinAssociationWithCode(BuildContext context, String code) {
    // TODO: Add your logic to validate the code and join the association
    print('Submitted Invite Code: $code');

    // Example action after submitting a code
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining association with code: $code')),
    );
  }
}
