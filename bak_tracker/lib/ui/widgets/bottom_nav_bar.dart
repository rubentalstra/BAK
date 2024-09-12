import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return isIOS
        ? CupertinoTabBar(
            // Native look for iOS
            currentIndex: selectedIndex,
            onTap: onTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home), // Home Tab
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.add), // Add Bak Tab
                label: 'Send Bak',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.time), // Pending Approvals Tab
                label: 'Approvals',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.book), // History Tab
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings), // Settings Tab
                label: 'Settings',
              ),
            ],
          )
        : BottomNavigationBar(
            // Native look for Android
            currentIndex: selectedIndex,
            onTap: onTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home), // Home Tab
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline), // Add Bak Tab
                label: 'Add Bak',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.hourglass_bottom), // Pending Approvals Tab
                label: 'Approvals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history), // History Tab
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings), // Settings Tab
                label: 'Settings',
              ),
            ],
          );
  }
}
