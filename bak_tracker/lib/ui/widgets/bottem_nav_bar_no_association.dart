import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class BottomNavBarNoAssociation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavBarNoAssociation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final theme = Theme.of(context);

    return isIOS
        ? CupertinoTabBar(
            // Native look for iOS
            currentIndex: selectedIndex,
            onTap: onTap,
            activeColor: theme
                .colorScheme.secondary, // Use secondary color for active tab
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home), // Home Tab (No association)
                label: 'Home',
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
            selectedItemColor: theme
                .colorScheme.secondary, // Use secondary color for active tab
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home), // Home Tab (No association)
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings), // Settings Tab
                label: 'Settings',
              ),
            ],
          );
  }
}
