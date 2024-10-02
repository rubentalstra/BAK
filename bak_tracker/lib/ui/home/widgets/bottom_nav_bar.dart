import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final int pendingBetsCount; // Ongoing bets count
  final int pendingBaksCount; // Pending baks count

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.pendingBetsCount, // Required to show badge for bets
    required this.pendingBaksCount, // Required to show badge for baks
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
      BottomNavigationBarItem(
        icon: badges.Badge(
          showBadge:
              pendingBaksCount > 0, // Only show badge if there are pending baks
          badgeContent: Text(
            pendingBaksCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.red, // Badge color for pending baks
          ),
          child: const FaIcon(FontAwesomeIcons.beerMugEmpty, size: 25),
        ),
        label: 'Bak',
      ),
      const BottomNavigationBarItem(
        icon: FaIcon(FontAwesomeIcons.wineBottle, size: 25),
        label: 'Chucked',
      ),
      BottomNavigationBarItem(
        icon: badges.Badge(
          showBadge:
              pendingBetsCount > 0, // Only show badge if there are pending bets
          badgeContent: Text(
            pendingBetsCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.red, // Badge color for pending bets
          ),
          child: const FaIcon(FontAwesomeIcons.dice, size: 25),
        ),
        label: 'Bets',
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
