import 'package:bak_tracker/ui/no_association/no_association_home_screen.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart';
import 'package:bak_tracker/ui/no_association/widgets/bottem_nav_bar_no_association.dart';
import 'package:flutter/material.dart';

class NoAssociationScreen extends StatefulWidget {
  const NoAssociationScreen({super.key});

  @override
  _NoAssociationScreenState createState() => _NoAssociationScreenState();
}

class _NoAssociationScreenState extends State<NoAssociationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      NoAssociationHomeScreen(),
      SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBarNoAssociation(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
