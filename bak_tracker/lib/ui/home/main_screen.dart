import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/home/bak/bak_screen.dart';
import 'package:bak_tracker/ui/home/approve_baks/approve_baks_screen.dart';
import 'package:bak_tracker/ui/home/home_screen.dart';
import 'package:bak_tracker/ui/home/bets_screen.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart.dart';
import 'package:bak_tracker/ui/home/widgets/bottom_nav_bar.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _pendingBaks = 0; // Track pending baks count
  bool _canApproveBaks = false; // Track approval permission

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // Listen for association changes and pending baks
    context.read<AssociationBloc>().stream.listen((state) {
      if (state is AssociationLoaded) {
        _canApproveBaks = state.memberData.canApproveBaks ||
            state.memberData.hasAllPermissions;

        _fetchPendingBaks(state.selectedAssociation.id);
        _updatePages(); // Update pages based on permission
      }
    });
  }

  // Update the pages based on user permissions
  void _updatePages() {
    setState(() {
      _pages = [
        const HomeScreen(), // Home
        const BakScreen(), // Send Bak
        const BetsScreen(), // Pending Approvals
        if (_canApproveBaks)
          const ApproveBaksScreen(), // Conditionally add Approve Baks
        const SettingsScreen(), // Settings
      ];
    });
  }

  // Fetch the number of pending baks for the badge
  Future<void> _fetchPendingBaks(String associationId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('bak_consumed')
        .select()
        .eq('association_id', associationId)
        .eq('status', 'pending');

    setState(() {
      _pendingBaks = response.length;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isNotEmpty
          ? _pages[_selectedIndex]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        pendingBaks: _pendingBaks, // Pass the pending baks count
        canApproveBaks: _canApproveBaks, // Pass the permission flag
      ),
    );
  }
}
