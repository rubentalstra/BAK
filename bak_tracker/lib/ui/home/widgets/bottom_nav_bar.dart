import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final int pendingBaks; // Pass pending baks count
  final bool canApproveBaks; // Pass permission flag

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.pendingBaks, // Required to show badge
    required this.canApproveBaks, // Required to conditionally show "Approve Baks"
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final theme = Theme.of(context);

    // List of items for the bottom navigation bar
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.local_drink),
        label: 'Bak',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.handshake_outlined),
        label: 'Bets',
      ),
      if (canApproveBaks) // Conditionally show Approve Baks tab
        BottomNavigationBarItem(
          icon: badges.Badge(
            showBadge:
                pendingBaks > 0, // Only show badge if there are pending baks
            badgeContent: Text(
              pendingBaks.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.red, // Customize badge color
            ),
            child: const Icon(Icons.history),
          ),
          label: 'Approve Baks',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    // Use CupertinoTabBar for iOS or BottomNavigationBar for Android
    return isIOS
        ? CupertinoTabBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            activeColor: theme.colorScheme.secondary, // Active tab color
            items: items,
          )
        : BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedIndex,
            onTap: onTap,
            selectedItemColor: theme.colorScheme.secondary, // Active tab color
            backgroundColor: theme.colorScheme.primary, // Background color
            unselectedItemColor: theme.colorScheme.onPrimary.withOpacity(0.6),
            items: items,
          );
  }
}
