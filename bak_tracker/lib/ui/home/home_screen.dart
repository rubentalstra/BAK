import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  // Updated from StatsScreen
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'), // Updated title
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Your Association Overview'),
            // Add your stats widgets here
          ],
        ),
      ),
    );
  }
}
