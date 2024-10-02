import 'dart:convert';
import 'dart:async';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/ui/home/bets/bets_screen.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/home/bak/bak_screen.dart';
import 'package:bak_tracker/ui/home/home_screen.dart';
import 'package:bak_tracker/ui/home/chucked/chucked_screen.dart';
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
  Timer? _approveBaksTimer;
  Timer? _pendingBaksAndBetsTimer;

  // Store badge counts outside the build method to prevent them from resetting
  int pendingBaksCount = 0;
  int pendingBetsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAssociations();
    _subscribeToBloc();
  }

  @override
  void dispose() {
    _approveBaksTimer?.cancel();
    _pendingBaksAndBetsTimer?.cancel();
    super.dispose();
  }

  void _subscribeToBloc() {
    final associationBloc = context.read<AssociationBloc>();
    associationBloc.stream.listen((state) {
      if (state is AssociationLoaded) {
        _canApproveBaks = state.memberData.canApproveBaks ||
            state.memberData.hasAllPermissions;

        // Update badge counts only if they have changed
        setState(() {
          pendingBaksCount = state.pendingBaksCount;
          pendingBetsCount = state.pendingBetsCount;
        });

        // Set up pages and polling based on loaded associations
        _setPages();
        _startPollingAproveBaks();
        _startPollingPendingBaksAndBets();
      }
    });
  }

  void _startPollingAproveBaks() {
    _approveBaksTimer?.cancel();
    if (_canApproveBaks && _selectedAssociation != null) {
      _approveBaksTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        context
            .read<AssociationBloc>()
            .add(RefreshPendingAproveBaks(_selectedAssociation!.id));
      });
    }
  }

  void _startPollingPendingBaksAndBets() {
    _pendingBaksAndBetsTimer?.cancel();
    if (_selectedAssociation != null) {
      _pendingBaksAndBetsTimer =
          Timer.periodic(const Duration(seconds: 30), (timer) {
        context
            .read<AssociationBloc>()
            .add(RefreshBaksAndBets(_selectedAssociation!.id));
      });
    }
  }

  Future<void> _fetchAssociations() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final List<dynamic> memberResponse = await supabase
        .from('association_members')
        .select('association_id')
        .eq('user_id', userId);

    if (memberResponse.isNotEmpty) {
      final associationIds =
          memberResponse.map((m) => m['association_id']).toList();
      final List<dynamic> response = await supabase
          .from('associations')
          .select()
          .inFilter('id', associationIds);

      setState(() {
        _associations =
            response.map((data) => AssociationModel.fromMap(data)).toList();
        _loadSavedAssociation();
      });
    }
  }

  Future<void> _loadSavedAssociation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAssociationJson = prefs.getString('selected_association');

    _selectedAssociation = savedAssociationJson != null
        ? _associations.firstWhere(
            (a) =>
                a.id ==
                AssociationModel.fromMap(jsonDecode(savedAssociationJson)).id,
            orElse: () => _associations.first)
        : _associations.first;

    if (_selectedAssociation != null) {
      context
          .read<AssociationBloc>()
          .add(SelectAssociation(selectedAssociation: _selectedAssociation!));
    }
    _setPages();
  }

  Future<void> _saveSelectedAssociation(AssociationModel association) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'selected_association', jsonEncode(association.toMap()));
  }

  void _onAssociationChanged(AssociationModel? newAssociation) {
    if (_selectedAssociation?.id != newAssociation?.id) {
      _selectedAssociation = newAssociation;
      _pages.clear();
      _saveSelectedAssociation(newAssociation!);
      context
          .read<AssociationBloc>()
          .add(SelectAssociation(selectedAssociation: newAssociation));
      _setPages();
    }
  }

  void _setPages() {
    if (_selectedAssociation != null) {
      _pages = [
        HomeScreen(
          associations: _associations,
          selectedAssociation: _selectedAssociation,
          onAssociationChanged: _onAssociationChanged,
        ),
        const BakScreen(),
        const ChuckedScreen(),
        const BetsScreen(),
        const SettingsScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex >= _pages.length && _pages.isNotEmpty) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: _pages.isNotEmpty
          ? _pages[_selectedIndex]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        pendingBaksCount: pendingBaksCount, // Persisted value
        pendingBetsCount: pendingBetsCount, // Persisted value
      ),
    );
  }
}
