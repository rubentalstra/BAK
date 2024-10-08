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
                    builder: (context) => const AssociationRequestScreen(),
                  ),
                );
              },
              child: const Text('Request Association'),
            ),
            ElevatedButton(
              onPressed: () => _showInviteCodeInput(context),
              child: const Text('Join Association'),
            ),
          ],
        ),
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
