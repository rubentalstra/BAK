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

  const HomeScreen({
    super.key,
    required this.associations,
    required this.selectedAssociation,
    required this.onAssociationChanged,
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

  @override
  void initState() {
    super.initState();
    _imageUploadService = ImageUploadService(supabase);
    _fetchLeaderboard(); // Initial fetch for the leaderboard
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger leaderboard reload if the selected association has changed
    if (oldWidget.selectedAssociation != widget.selectedAssociation) {
      _fetchLeaderboard();
    }
  }

  @override
  void dispose() {
    _associationBlocSubscription
        ?.cancel(); // Cancel subscription when the widget is disposed
    super.dispose();
  }

  // Fetch leaderboard for the selected association
  Future<void> _fetchLeaderboard() async {
    if (widget.selectedAssociation == null) return;

    setState(() {
      _isLoading = true;
      _leaderboardEntries = [];
    });

    // Dispatch event to update the association in the bloc
    context.read<AssociationBloc>().add(SelectAssociation(
          selectedAssociation: widget.selectedAssociation!,
        ));

    // Listen for the AssociationBloc updates
    _associationBlocSubscription
        ?.cancel(); // Cancel previous subscription if any
    _associationBlocSubscription =
        context.read<AssociationBloc>().stream.listen((state) {
      if (state is AssociationLoaded) {
        if (!mounted)
          return; // Prevent setting state if the widget is not mounted

        // Map the new state to leaderboard entries
        List<LeaderboardEntry> newLeaderboardEntries =
            state.members.map((member) {
          return LeaderboardEntry(
            rank: 0,
            name: member.name!,
            profileImagePath: member.profileImagePath,
            baksConsumed: member.baksConsumed,
            baksDebt: member.baksReceived,
          );
        }).toList();

        // Sort the leaderboard entries
        newLeaderboardEntries
            .sort((a, b) => b.baksConsumed.compareTo(a.baksConsumed));

        // Assign ranks
        for (int i = 0; i < newLeaderboardEntries.length; i++) {
          newLeaderboardEntries[i] =
              newLeaderboardEntries[i].copyWith(rank: i + 1);
        }

        // Update state only if the leaderboard entries have changed
        if (!_areEntriesEqual(newLeaderboardEntries, _leaderboardEntries)) {
          setState(() {
            // _previousLeaderboardEntries = _leaderboardEntries;
            _leaderboardEntries = newLeaderboardEntries;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  // Helper method to check if two lists of leaderboard entries are equal
  bool _areEntriesEqual(
      List<LeaderboardEntry> newEntries, List<LeaderboardEntry> oldEntries) {
    if (newEntries.length != oldEntries.length) return false;

    for (int i = 0; i < newEntries.length; i++) {
      if (newEntries[i] != oldEntries[i]) return false;
    }
    return true;
  }

  void _handleAssociationChange(AssociationModel? newAssociation) {
    widget.onAssociationChanged(newAssociation); // Inform the parent widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.associations.length > 1
            ? DropdownButtonHideUnderline(
                child: DropdownButton<AssociationModel>(
                  value: widget.selectedAssociation,
                  onChanged: _handleAssociationChange, // Trigger reload
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
      body: Padding(
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
    );
  }
}
