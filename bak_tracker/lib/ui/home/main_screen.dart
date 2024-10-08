import 'dart:async';
import 'dart:convert';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/ui/home/bak/bak_screen.dart';
import 'package:bak_tracker/ui/home/bets/bets_screen.dart';
import 'package:bak_tracker/ui/home/chucked/chucked_screen.dart';
import 'package:bak_tracker/ui/home/home_screen.dart';
import 'package:bak_tracker/ui/home/widgets/bottom_nav_bar.dart';
import 'package:bak_tracker/ui/settings/settings_screen.dart';
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

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<AssociationModel> _associations = [];
  AssociationModel? _selectedAssociation;
  Timer? _approveBaksTimer;
  Timer? _pendingBaksAndBetsTimer;

  int pendingBaksCount = 0;
  int pendingBetsCount = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _approveBaksTimer?.cancel();
    _pendingBaksAndBetsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _fetchAssociations();
    await _loadSavedAssociation();
    _startPollingApproveBaks();
    _startPollingPendingBaksAndBets();
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

      _associations =
          response.map((data) => AssociationModel.fromMap(data)).toList();
    }
  }

  Future<void> _loadSavedAssociation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAssociationJson = prefs.getString('selected_association');

    if (savedAssociationJson != null) {
      final savedAssociation =
          AssociationModel.fromMap(jsonDecode(savedAssociationJson));
      _selectedAssociation = _associations.firstWhere(
          (a) => a.id == savedAssociation.id,
          orElse: () => _associations.first);
    } else {
      _selectedAssociation = _associations.first;
    }

    _updateSelectedAssociation(_selectedAssociation);
  }

  void _updateSelectedAssociation(AssociationModel? association) {
    if (association != null) {
      context
          .read<AssociationBloc>()
          .add(SelectAssociation(selectedAssociation: association));
    }
  }

  void _onAssociationChanged(AssociationModel? newAssociation) {
    if (_selectedAssociation?.id != newAssociation?.id) {
      setState(() {
        _selectedAssociation = newAssociation;
      });
      _updateSelectedAssociation(newAssociation);
    }
  }

  void _startPollingApproveBaks() {
    _approveBaksTimer?.cancel();

    if (_selectedAssociation != null) {
      _approveBaksTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _triggerApproveBaksRefresh();
      });
    }
  }

  void _triggerApproveBaksRefresh() {
    if (_selectedAssociation != null) {
      context
          .read<AssociationBloc>()
          .add(RefreshPendingApproveBaks(_selectedAssociation!.id));
    }
  }

  void _startPollingPendingBaksAndBets() {
    _pendingBaksAndBetsTimer?.cancel();

    if (_selectedAssociation != null) {
      _pendingBaksAndBetsTimer =
          Timer.periodic(const Duration(seconds: 30), (_) {
        _triggerBaksAndBetsRefresh();
      });
    }
  }

  void _triggerBaksAndBetsRefresh() {
    if (_selectedAssociation != null) {
      context
          .read<AssociationBloc>()
          .add(RefreshBaksAndBets(_selectedAssociation!.id));
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
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssociationBloc, AssociationState>(
      listener: (context, state) {
        if (state is AssociationLoaded) {
          final memberData = state.memberData;
          final hasApproveBaksPermission = memberData.permissions
                  .hasPermission(PermissionEnum.canApproveBaks) ||
              memberData.permissions
                  .hasPermission(PermissionEnum.hasAllPermissions);

          if (hasApproveBaksPermission) {
            _startPollingApproveBaks();
          }

          setState(() {
            pendingBaksCount = state.pendingBaksCount;
            pendingBetsCount = state.pendingBetsCount;
          });

          _startPollingPendingBaksAndBets();
        }
      },
      child: Scaffold(
        body: _buildPages()[_selectedIndex],
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          pendingBaksCount: pendingBaksCount,
          pendingBetsCount: pendingBetsCount,
        ),
      ),
    );
  }
}
