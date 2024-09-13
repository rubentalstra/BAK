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
                icon: Icon(CupertinoIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_drink),
                label: 'Bak',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.handshake_outlined),
                label: 'Bets',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.book),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
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
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_drink),
                label: 'Bak',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.handshake_outlined),
                label: 'Bets',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
  }
}
