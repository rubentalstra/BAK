import 'dart:convert';

import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AssociationModel> _associations = [];
  AssociationModel? _selectedAssociation;
  List<LeaderboardEntry> _leaderboardEntries = [];
  bool _isLoading = true; // Add a loading flag

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      // Handle unauthenticated state
      return;
    }

    // Start loading
    setState(() {
      _isLoading = true;
    });

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

      if (response.isNotEmpty) {
        setState(() {
          _associations = response
              .map((data) =>
                  AssociationModel.fromMap(data as Map<String, dynamic>))
              .toList();
          _selectedAssociation =
              _associations.isNotEmpty ? _associations.first : null;

          if (_selectedAssociation != null) {
            // Dispatch the SelectAssociation event when the first association is selected
            context.read<AssociationBloc>().add(
                  SelectAssociation(selectedAssociation: _selectedAssociation!),
                );

            // Fetch leaderboard for the selected association
            _fetchLeaderboard();
          }
        });
      }
    }

    // Stop loading
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchLeaderboard() async {
    if (_selectedAssociation == null) return;

    final supabase = Supabase.instance.client;

    // Start loading
    setState(() {
      _isLoading = true;
    });

    // Fetch association members for the selected association
    final List<dynamic> memberResponse = await supabase
        .from('association_members')
        .select(
            'user_id (id, name), association_id, role, permissions, joined_at, baks_received, baks_consumed')
        .eq('association_id', _selectedAssociation!.id);

    if (memberResponse.isNotEmpty) {
      // Convert the fetched data to AssociationMemberModel
      List<AssociationMemberModel> members = memberResponse.map((data) {
        // The 'user_id' field is a nested map containing 'id' and 'name'
        final userMap = data['user_id'] as Map<String, dynamic>;

        return AssociationMemberModel(
          userId: userMap['id'],
          name: userMap['name'] ?? 'Unknown User', // Fallback if name is null
          associationId: data['association_id'],
          role: data['role'],
          permissions: data['permissions'] is String
              ? jsonDecode(data['permissions']) as Map<String, dynamic>
              : data['permissions'] as Map<String, dynamic>,
          joinedAt: DateTime.parse(data['joined_at']),
          baksReceived: data['baks_received'],
          baksConsumed: data['baks_consumed'],
        );
      }).toList();

      // Create leaderboard entries based on members
      setState(() {
        _leaderboardEntries = members.map((member) {
          return LeaderboardEntry(
            rank: 0, // You can assign a rank based on sorting later
            username: member.name ??
                member.userId, // Use name if available, else fallback to userId
            baksConsumed: member.baksConsumed,
            baksDebt: member.baksReceived, // Assuming this is the debt
          );
        }).toList();

        // Sort leaderboard entries by baksConsumed in descending order
        _leaderboardEntries
            .sort((a, b) => b.baksConsumed.compareTo(a.baksConsumed));

        // Assign ranks based on sorted order
        for (int i = 0; i < _leaderboardEntries.length; i++) {
          _leaderboardEntries[i] = _leaderboardEntries[i].copyWith(rank: i + 1);
        }
      });
    }

    // Stop loading
    setState(() {
      _isLoading = false;
    });
  }

  void _onAssociationChanged(AssociationModel? newAssociation) {
    setState(() {
      _selectedAssociation = newAssociation;
      _leaderboardEntries = []; // Clear leaderboard entries
    });

    // Dispatch the SelectAssociation event
    if (newAssociation != null) {
      context.read<AssociationBloc>().add(
            SelectAssociation(selectedAssociation: newAssociation),
          );

      _fetchLeaderboard(); // Fetch leaderboard for the new association
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _associations.length > 1
            ? DropdownButtonHideUnderline(
                child: DropdownButton<AssociationModel>(
                  value: _selectedAssociation,
                  onChanged: _onAssociationChanged,
                  dropdownColor: AppColors.lightPrimaryVariant,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Theme.of(context).iconTheme.color),
                  items: _associations.map((association) {
                    return DropdownMenuItem(
                      value: association,
                      child: Text(association.name,
                          style: Theme.of(context).dropdownMenuTheme.textStyle),
                    );
                  }).toList(),
                ),
              )
            : Text(
                _selectedAssociation?.name ?? 'Loading...',
                style: Theme.of(context).dropdownMenuTheme.textStyle,
              ),
      ),
      body: _isLoading // Display loading animation while fetching data
          ? const Center(
              child: CircularProgressIndicator(), // Default loading spinner
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedAssociation != null) ...[
                    Expanded(
                      child: LeaderboardWidget(
                        entries: _leaderboardEntries,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
