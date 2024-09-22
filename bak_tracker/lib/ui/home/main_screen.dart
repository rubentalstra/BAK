import 'dart:convert';
import 'dart:async'; // For polling

import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/home/bak/bak_screen.dart';
import 'package:bak_tracker/ui/home/approve_baks/approve_baks_screen.dart';
import 'package:bak_tracker/ui/home/home_screen.dart';
import 'package:bak_tracker/ui/home/bets_screen.dart';
import 'package:bak_tracker/ui/home/widgets/bottom_nav_bar.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _canApproveBaks = false;
  List<AssociationModel> _associations = [];
  AssociationModel? _selectedAssociation;
  List<Widget> _pages = [];
  Timer? _timer; // Timer for periodic polling

  @override
  void initState() {
    super.initState();
    _fetchAssociations();
    // only if the user has the permission to approve baks
    _startPollingPendingBaks(); // Start polling for pending baks

    // Listen for changes from the AssociationBloc
    context.read<AssociationBloc>().stream.listen((state) {
      if (state is AssociationLoaded) {
        _canApproveBaks = state.memberData.canApproveBaks ||
            state.memberData.hasAllPermissions;
        _setPages();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel polling when the widget is disposed
    super.dispose();
  }

  // Poll for pending baks every 30 seconds and refresh using Bloc
  void _startPollingPendingBaks() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_selectedAssociation != null) {
        print('Refreshing pending baks...');
        // Call RefreshPendingBaks event every 30 seconds
        context
            .read<AssociationBloc>()
            .add(RefreshPendingBaks(_selectedAssociation!.id));
      }
    });
  }

  Future<void> _fetchAssociations() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Fetch associations where the user is a member
    final List<dynamic> memberResponse = await supabase
        .from('association_members')
        .select('association_id')
        .eq('user_id', userId);

    if (memberResponse.isNotEmpty) {
      final associationIds =
          memberResponse.map((m) => m['association_id']).toList();

      // Fetch associations by IDs
      final List<dynamic> response = await supabase
          .from('associations')
          .select()
          .inFilter('id', associationIds);

      setState(() {
        _associations = response
            .map((data) =>
                AssociationModel.fromMap(data as Map<String, dynamic>))
            .toList();
        _loadSavedAssociation();
      });
    }
  }

  Future<void> _loadSavedAssociation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAssociationJson = prefs.getString('selected_association');

    if (savedAssociationJson != null) {
      final savedAssociation = AssociationModel.fromMap(
          jsonDecode(savedAssociationJson) as Map<String, dynamic>);
      _selectedAssociation = _associations.firstWhere(
        (association) => association.id == savedAssociation.id,
        orElse: () => _associations.first,
      );
    } else if (_associations.isNotEmpty) {
      _selectedAssociation = _associations.first;
    }

    if (_selectedAssociation != null) {
      context.read<AssociationBloc>().add(
            SelectAssociation(selectedAssociation: _selectedAssociation!),
          );
    }

    _setPages();
  }

  void _setPages() {
    _pages = [
      HomeScreen(
        associations: _associations,
        selectedAssociation: _selectedAssociation,
        onAssociationChanged: _onAssociationChanged,
      ),
      const BakScreen(),
      const BetsScreen(),
      if (_canApproveBaks) const ApproveBaksScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onAssociationChanged(AssociationModel? newAssociation) {
    setState(() {
      _selectedAssociation = newAssociation;
      _pages = [];
    });

    if (newAssociation != null) {
      _saveSelectedAssociation(newAssociation);
      context.read<AssociationBloc>().add(
            SelectAssociation(selectedAssociation: newAssociation),
          );
      _setPages();
    }
  }

  Future<void> _saveSelectedAssociation(AssociationModel association) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'selected_association', jsonEncode(association.toMap()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssociationBloc, AssociationState>(
      builder: (context, state) {
        int pendingBaksCount = 0;

        if (state is AssociationLoaded) {
          pendingBaksCount = state.pendingBaksCount;
        }

        return Scaffold(
          body: _pages.isNotEmpty
              ? _pages[_selectedIndex]
              : const Center(child: CircularProgressIndicator()),
          bottomNavigationBar: BottomNavBar(
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
            pendingBaks: pendingBaksCount, // Pass the pending baks count
            canApproveBaks: _canApproveBaks,
          ),
        );
      },
    );
  }
}
