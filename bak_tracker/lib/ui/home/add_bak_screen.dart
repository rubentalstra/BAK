import 'package:flutter/material.dart';

class AddBakScreen extends StatelessWidget {
  const AddBakScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bak'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select Member'),
            // Add member selection logic here
            const Text('Enter Number of Bakken'),
            // Add form for entering the number of "bakken"
          ],
        ),
      ),
    );
  }
}
