import 'package:badges/badges.dart' as badges;
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return BlocBuilder<AssociationBloc, AssociationState>(
      builder: (context, state) {
        int pendingBaksCount = 0;
        int pendingBetsCount = 0;

        if (state is AssociationLoaded) {
          pendingBaksCount = state.pendingBaksCount;
          pendingBetsCount = state.pendingBetsCount;
        }

        BottomNavigationBarItem buildBadgeItem({
          required IconData icon,
          required String label,
          required int badgeCount,
        }) {
          return BottomNavigationBarItem(
            icon: badges.Badge(
              showBadge: badgeCount > 0,
              badgeContent: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
              ),
              child: FaIcon(icon, size: 25),
            ),
            label: label,
          );
        }

        final items = [
          const BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house, size: 25),
            label: 'Home',
          ),
          buildBadgeItem(
            icon: FontAwesomeIcons.beerMugEmpty,
            label: 'Bak',
            badgeCount: pendingBaksCount,
          ),
          const BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.wineBottle, size: 25),
            label: 'Chucked',
          ),
          buildBadgeItem(
            icon: FontAwesomeIcons.dice,
            label: 'Bets',
            badgeCount: pendingBetsCount,
          ),
          const BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.user, size: 25),
            label: 'Profile',
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
                type: BottomNavigationBarType.fixed,
                currentIndex: selectedIndex,
                onTap: onTap,
                selectedItemColor: theme.colorScheme.secondary,
                unselectedItemColor:
                    theme.colorScheme.onPrimary.withOpacity(0.6),
                items: items,
              );
      },
    );
  }
}
