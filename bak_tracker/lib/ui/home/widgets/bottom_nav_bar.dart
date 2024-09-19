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

    // Create the common list of items
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
            showBadge: pendingBaks > 0, // Show badge if pendingBaks > 0
            badgeContent: Text(
              pendingBaks.toString(),
              style: const TextStyle(color: Colors.white),
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

    return isIOS
        ? CupertinoTabBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            activeColor: theme
                .colorScheme.secondary, // Use secondary color for active tab
            items: items,
          )
        : BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            selectedItemColor: theme
                .colorScheme.secondary, // Use secondary color for active tab
            items: items,
          );
  }
}
