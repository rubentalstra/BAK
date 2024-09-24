import 'dart:async';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_widget.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';

class HomeScreen extends StatefulWidget {
  final List<AssociationModel> associations;
  final AssociationModel? selectedAssociation;
  final ValueChanged<AssociationModel?> onAssociationChanged;
  final Future<void> Function()
      onRefreshAssociations; // Pass refresh logic from MainScreen

  const HomeScreen({
    super.key,
    required this.associations,
    required this.selectedAssociation,
    required this.onAssociationChanged,
    required this.onRefreshAssociations,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<LeaderboardEntry> _leaderboardEntries = [];
  final supabase = Supabase.instance.client;
  late ImageUploadService _imageUploadService;
  StreamSubscription? _associationBlocSubscription;
  bool _isLoading = true;
  bool _didFetch = false; // To track if data was already fetched

  @override
  void initState() {
    super.initState();
    _imageUploadService = ImageUploadService(supabase);

    // Listen for AssociationBloc updates
    _associationBlocSubscription =
        context.read<AssociationBloc>().stream.listen((state) {
      if (state is AssociationLoaded && mounted) {
        _updateLeaderboard(state);
      }
    });

    if (!_didFetch) {
      _fetchLeaderboard();
    }
  }

  @override
  void dispose() {
    _associationBlocSubscription
        ?.cancel(); // Cancel subscription when the widget is disposed
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only trigger leaderboard reload if the selected association has changed
    if (oldWidget.selectedAssociation?.id != widget.selectedAssociation?.id) {
      _fetchLeaderboard();
    }
  }

  // Fetch leaderboard for the selected association
  Future<void> _fetchLeaderboard() async {
    if (widget.selectedAssociation == null) return;

    setState(() {
      _isLoading = true; // Set loading to true before fetching
      _leaderboardEntries = [];
    });

    _didFetch = true;

    // Dispatch event to update the association in the bloc if needed
    final currentState = context.read<AssociationBloc>().state;
    if (currentState is AssociationLoaded &&
        currentState.selectedAssociation.id == widget.selectedAssociation?.id) {
      // Association is already loaded, no need to fetch again
      _updateLeaderboard(currentState);
      return;
    }

    // Dispatch the event only if the association has not been loaded
    context.read<AssociationBloc>().add(SelectAssociation(
          selectedAssociation: widget.selectedAssociation!,
        ));
  }

  // Update leaderboard once data is loaded
  void _updateLeaderboard(AssociationLoaded state) {
    List<LeaderboardEntry> newLeaderboardEntries = state.members.map((member) {
      return LeaderboardEntry(
        rank: 0,
        name: member.name!,
        profileImagePath: member.profileImagePath,
        baksConsumed: member.baksConsumed,
        baksDebt: member.baksReceived,
      );
    }).toList();

    // Sort and assign ranks
    newLeaderboardEntries
        .sort((a, b) => b.baksConsumed.compareTo(a.baksConsumed));
    for (int i = 0; i < newLeaderboardEntries.length; i++) {
      newLeaderboardEntries[i] = newLeaderboardEntries[i].copyWith(rank: i + 1);
    }

    // Update state only if the leaderboard entries have changed
    if (!_areEntriesEqual(newLeaderboardEntries, _leaderboardEntries)) {
      setState(() {
        _leaderboardEntries = newLeaderboardEntries;
        _isLoading = false; // Stop loading once data is updated
      });
    } else {
      setState(() {
        _isLoading = false; // Stop loading even if data hasn't changed
      });
    }
  }

  // Check if two lists of leaderboard entries are equal
  bool _areEntriesEqual(
      List<LeaderboardEntry> newEntries, List<LeaderboardEntry> oldEntries) {
    if (newEntries.length != oldEntries.length) return false;

    for (int i = 0; i < newEntries.length; i++) {
      if (newEntries[i] != oldEntries[i]) return false;
    }
    return true;
  }

  Future<void> _refreshLeaderboard() async {
    setState(() {
      _isLoading = true; // Set loading to true for pull-to-refresh
    });
    // Call refresh logic from MainScreen (which refreshes associations and leaderboard)
    await widget.onRefreshAssociations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.associations.length > 1
            ? DropdownButtonHideUnderline(
                child: DropdownButton<AssociationModel>(
                  value: widget.selectedAssociation,
                  onChanged: widget.onAssociationChanged, // Trigger reload
                  dropdownColor: AppColors.lightPrimaryVariant,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Theme.of(context).iconTheme.color),
                  items: widget.associations.map((association) {
                    return DropdownMenuItem(
                      value: association,
                      child: Text(association.name,
                          style: Theme.of(context).dropdownMenuTheme.textStyle),
                    );
                  }).toList(),
                ),
              )
            : Text(
                widget.selectedAssociation?.name ?? 'Loading...',
                style: Theme.of(context).dropdownMenuTheme.textStyle,
              ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLeaderboard, // Pull-to-refresh functionality
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectedAssociation != null)
                Expanded(
                  child: LeaderboardWidget(
                    entries: _leaderboardEntries,
                    imageUploadService: _imageUploadService,
                    isLoading: _isLoading, // Pass the isLoading flag here
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
