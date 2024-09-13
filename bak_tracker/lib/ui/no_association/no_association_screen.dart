import 'package:bak_tracker/ui/no_association/no_association_home_screen.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart.dart';
import 'package:bak_tracker/ui/widgets/bottem_nav_bar_no_association.dart';
import 'package:flutter/material.dart';

class NoAssociationScreen extends StatefulWidget {
  const NoAssociationScreen({Key? key}) : super(key: key);

  @override
  _NoAssociationScreenState createState() => _NoAssociationScreenState();
}

class _NoAssociationScreenState extends State<NoAssociationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const NoAssociationHomeScreen(), // Home (No association)
    const SettingsScreen(), // Settings (Join/Create Association)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBarNoAssociation(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}