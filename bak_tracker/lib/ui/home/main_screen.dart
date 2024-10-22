// main_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/user/user_bloc.dart';
import 'package:bak_tracker/bloc/user/user_event.dart';
import 'package:bak_tracker/ui/home/bak/bak_screen.dart';
import 'package:bak_tracker/ui/home/bets/bets_screen.dart';
import 'package:bak_tracker/ui/home/chucked/chucked_screen.dart';
import 'package:bak_tracker/ui/home/home_screen.dart';
import 'package:bak_tracker/ui/home/widgets/bottom_nav_bar.dart';
import 'package:bak_tracker/ui/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  List<AssociationModel> _associations = [];
  AssociationModel? _selectedAssociation;
  Timer? _pendingCountersTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _startPendingCountersTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingCountersTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      context.read<UserBloc>().add(LoadUser(currentUser.id));
    }

    await _fetchAssociations();
    await _loadSavedAssociation();
  }

  Future<void> _fetchAssociations() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final memberResponse = await supabase
        .from('association_members')
        .select('association_id')
        .eq('user_id', userId);

    if (memberResponse.isNotEmpty) {
      final associationIds =
          memberResponse.map((m) => m['association_id']).toList();
      final response = await supabase
          .from('associations')
          .select()
          .inFilter('id', associationIds);

      setState(() {
        _associations = response
            .map<AssociationModel>((data) => AssociationModel.fromMap(data))
            .toList();
      });
    }
  }

  Future<void> _loadSavedAssociation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAssociationJson = prefs.getString('selected_association');

    if (savedAssociationJson != null) {
      final savedAssociation =
          AssociationModel.fromMap(jsonDecode(savedAssociationJson));
      final association = _associations.firstWhere(
          (a) => a.id == savedAssociation.id,
          orElse: () => _associations.first);
      _updateSelectedAssociation(association);
    } else if (_associations.isNotEmpty) {
      _updateSelectedAssociation(_associations.first);
    }
  }

  void _updateSelectedAssociation(AssociationModel? association) {
    if (association != null) {
      setState(() {
        _selectedAssociation = association;
      });
      context
          .read<AssociationBloc>()
          .add(SelectAssociation(selectedAssociation: association));
      // Also refresh pending counters when association changes
      _refreshPendingCounters();
    }
  }

  void _onAssociationChanged(AssociationModel? newAssociation) {
    if (_selectedAssociation?.id != newAssociation?.id) {
      _updateSelectedAssociation(newAssociation);
    }
  }

  void _startPendingCountersTimer() {
    _pendingCountersTimer?.cancel();
    // Fetch counts every 5 minutes
    _pendingCountersTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshPendingCounters();
    });
  }

  void _refreshPendingCounters() {
    if (_selectedAssociation != null) {
      final associationId = _selectedAssociation!.id;
      context.read<AssociationBloc>().add(
            RefreshBaksAndBets(associationId),
          );
      context.read<AssociationBloc>().add(
            RefreshPendingApproveBaks(associationId),
          );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_selectedAssociation != null) {
        context
            .read<AssociationBloc>()
            .add(SelectAssociation(selectedAssociation: _selectedAssociation!));
        // Also refresh pending counters when app resumes
        _refreshPendingCounters();
      }
    }
  }

  List<Widget> _buildPages() {
    return [
      HomeScreen(
        associations: _associations,
        selectedAssociation: _selectedAssociation,
        onAssociationChanged: _onAssociationChanged,
      ),
      const BakScreen(),
      const ChuckedScreen(),
      const BetsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPages()[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Optionally refresh counters when navigating to certain tabs
          if (index == 1 || index == 3) {
            // BAKs and Bets tabs
            _refreshPendingCounters();
          }
        },
      ),
    );
  }
}
