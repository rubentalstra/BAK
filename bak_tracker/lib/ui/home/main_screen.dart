import 'dart:convert';
import 'dart:async'; // For polling

import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart';
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
  Timer? _timer; // Timer for periodic polling

  @override
  void initState() {
    super.initState();
    _fetchAssociations();

    // Listen for changes from the AssociationBloc
    context.read<AssociationBloc>().stream.listen((state) {
      if (state is AssociationLoaded) {
        _canApproveBaks = state.memberData.canApproveBaks ||
            state.memberData.hasAllPermissions;
        _startPollingPendingBaks();
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
    _timer?.cancel(); // Ensure any previous timer is cancelled
    if (_selectedAssociation != null && _canApproveBaks) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        context
            .read<AssociationBloc>()
            .add(RefreshPendingBaks(_selectedAssociation!.id));
      });
    }
  }

  Future<void> _fetchAssociations({bool refresh = false}) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Save the currently selected association ID before refreshing
    final currentSelectedAssociationId = _selectedAssociation?.id;

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

      if (mounted) {
        setState(() {
          _associations = response
              .map((data) =>
                  AssociationModel.fromMap(data as Map<String, dynamic>))
              .toList();

          // Check if the current association is still in the new associations list
          if (currentSelectedAssociationId != null) {
            _selectedAssociation = _associations.firstWhere(
              (association) => association.id == currentSelectedAssociationId,
              orElse: () =>
                  _associations.first, // Fallback to the first if not found
            );
          } else {
            _selectedAssociation = _associations.first;
          }

          if (refresh) {
            _onAssociationChanged(_selectedAssociation);
          } else {
            _loadSavedAssociation();
          }
        });
      }
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
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Trigger data refresh if switching to the homepage (index = 0)
    if (index == 0) {
      // Instead of using a key, pass a function to HomeScreen to trigger refresh
      _fetchAssociations(refresh: true);
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

        final pages = [
          HomeScreen(
            associations: _associations,
            selectedAssociation: _selectedAssociation,
            onAssociationChanged: _onAssociationChanged,
            onRefreshAssociations: () =>
                _fetchAssociations(refresh: true), // Pass refresh logic
          ),
          const BakScreen(),
          const BetsScreen(),
          if (_canApproveBaks) const ApproveBaksScreen(),
          const SettingsScreen(),
        ];

        return Scaffold(
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavBar(
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
            pendingBaks: pendingBaksCount,
            canApproveBaks: _canApproveBaks,
          ),
        );
      },
    );
  }

  void _onAssociationChanged(AssociationModel? newAssociation) {
    setState(() {
      _selectedAssociation = newAssociation;
    });

    if (newAssociation != null) {
      _saveSelectedAssociation(newAssociation);
      context.read<AssociationBloc>().add(
            SelectAssociation(selectedAssociation: newAssociation),
          );
    }
  }
}
