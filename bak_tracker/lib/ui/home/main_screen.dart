import 'package:bak_tracker/ui/home/bak/bak_screen.dart';
import 'package:bak_tracker/ui/home/history_screen.dart';
import 'package:bak_tracker/ui/home/home_screen.dart';
import 'package:bak_tracker/ui/home/bets_screen.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart.dart';
import 'package:bak_tracker/ui/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(), // Home
    const BakScreen(), // Send Bak
    const BetsScreen(), // Pending Approvals
    const HistoryScreen(), // History
    const SettingsScreen(), // Settings
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
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
