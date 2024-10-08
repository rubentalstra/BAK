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
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final theme = Theme.of(context);
    final items = const [
      BottomNavigationBarItem(
        icon: Icon(FontAwesomeIcons.house, size: 25), // Home Tab
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(FontAwesomeIcons.gear, size: 25), // Settings Tab
        label: 'Settings',
      ),
    ];

    return isIOS
        ? CupertinoTabBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            activeColor: theme.colorScheme.secondary,
            items: items,
          )
        : BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            selectedItemColor: theme.colorScheme.secondary,
            items: items,
          );
  }
}
