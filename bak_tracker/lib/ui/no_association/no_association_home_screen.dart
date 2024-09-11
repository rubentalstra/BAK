import 'package:flutter/material.dart';

class NoAssociationHomeScreen extends StatelessWidget {
  const NoAssociationHomeScreen({Key? key}) : super(key: key);

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
                // Logic for joining an association
              },
              child: const Text('Join Association'),
            ),
          ],
        ),
      ),
    );
  }
}
