import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    final theme = Theme.of(context);
    final isIOS = theme.platform == TargetPlatform.iOS;

    // List of items for the bottom navigation bar
    const items = [
      BottomNavigationBarItem(
        icon: Icon(FontAwesomeIcons.house, size: 25), // Home Tab
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(FontAwesomeIcons.user, size: 25), // Profile Tab
        label: 'Profile',
      ),
    ];

    // Platform-specific bottom navigation bar (CupertinoTabBar for iOS)
    return isIOS
        ? CupertinoTabBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            activeColor: theme.colorScheme.secondary, // Active tab color
            items: items,
          )
        : BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            selectedItemColor: theme.colorScheme.secondary, // Active tab color
            unselectedItemColor: theme.colorScheme.onPrimary
                .withOpacity(0.6), // Inactive tab color
            items: items,
          );
  }
}
