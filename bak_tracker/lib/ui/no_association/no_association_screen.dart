import 'package:flutter/material.dart';

class NoAssociationScreen extends StatelessWidget {
  const NoAssociationScreen({Key? key}) : super(key: key);

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
                // Logic to join an association using a code
              },
              child: const Text('Join Association'),
            )
          ],
        ),
      ),
    );
  }
}
