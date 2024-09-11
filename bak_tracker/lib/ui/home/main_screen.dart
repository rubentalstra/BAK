import 'package:bak_tracker/ui/home/add_bak_screen.dart';
import 'package:bak_tracker/ui/home/history_screen.dart';
import 'package:bak_tracker/ui/home/home_screen.dart';
import 'package:bak_tracker/ui/home/pending_approval_screen.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart.dart';
import 'package:bak_tracker/ui/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  // Updated from HomeScreen to MainScreen for better clarity
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(), // Updated: Main dashboard for stats & leaderboard
    const AddBakScreen(), // Add Bak
    const PendingApprovalsScreen(), // Pending Approvals
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
