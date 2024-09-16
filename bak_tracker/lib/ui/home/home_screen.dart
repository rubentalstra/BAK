import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/board_year_model.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AssociationModel> _associations = [];
  List<BoardYearModel> _boardYears = [];
  AssociationModel? _selectedAssociation;
  BoardYearModel? _selectedBoardYear;
  List<LeaderboardEntry> _leaderboardEntries = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchDemoLeaderboardData();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      // Handle unauthenticated state
      return;
    }

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
        });

        // Fetch board years if an association is selected
        if (_selectedAssociation != null) {
          final List<dynamic> boardYearResponse = await supabase
              .from('board_years')
              .select()
              .eq('association_id', _selectedAssociation!.id);

          if (boardYearResponse.isNotEmpty) {
            setState(() {
              _boardYears = boardYearResponse
                  .map((data) =>
                      BoardYearModel.fromMap(data as Map<String, dynamic>))
                  .toList();
              _selectedBoardYear =
                  _boardYears.isNotEmpty ? _boardYears.first : null;
            });

            // Fetch leaderboard entries
            _fetchDemoLeaderboardData();
          }
        }
      }
    }
  }

  void _fetchDemoLeaderboardData() {
    // Creating some demo leaderboard data
    _leaderboardEntries = [
      LeaderboardEntry(
        rank: 1,
        username: 'Alice',
        baksConsumed: 50,
        baksDebt: 20,
      ),
      LeaderboardEntry(
        rank: 2,
        username: 'Bob',
        baksConsumed: 40,
        baksDebt: 15,
      ),
      LeaderboardEntry(
        rank: 3,
        username: 'Charlie',
        baksConsumed: 35,
        baksDebt: 25,
      ),
      LeaderboardEntry(
        rank: 4,
        username: 'David',
        baksConsumed: 30,
        baksDebt: 10,
      ),
      LeaderboardEntry(
        rank: 5,
        username: 'Eve',
        baksConsumed: 25,
        baksDebt: 5,
      ),
    ];

    setState(() {});
  }

  // Future<void> _fetchLeaderboard() async {
  //   final supabase = Supabase.instance.client;

  //   // Fetch leaderboard entries
  //   if (_selectedAssociation != null && _selectedBoardYear != null) {
  //     final List<dynamic> response = await supabase
  //         .from('leaderboard') // Assuming you have a leaderboard table
  //         .select()
  //         .eq('association_id', _selectedAssociation!.id)
  //         .eq('board_year_id', _selectedBoardYear!.id)
  //         .order('rank', ascending: true);

  //     if (response.isNotEmpty) {
  //       setState(() {
  //         _leaderboardEntries = (response).map((data) {
  //           final map = data as Map<String, dynamic>;
  //           return LeaderboardEntry(
  //             rank: map['rank'],
  //             username: map['username'],
  //             baksConsumed: map['baks_consumed'],
  //             baksDebt: map['baks_debt'],
  //           );
  //         }).toList();
  //       });
  //     }
  //   }
  // }

  void _onAssociationChanged(AssociationModel? newAssociation) {
    setState(() {
      _selectedAssociation = newAssociation;
      _selectedBoardYear = null; // Reset board year selection
      _leaderboardEntries = []; // Clear leaderboard entries
    });
    _fetchData(); // Re-fetch board years and leaderboard based on new association
  }

  void _onBoardYearChanged(BoardYearModel? newBoardYear) {
    setState(() {
      _selectedBoardYear = newBoardYear;
      _leaderboardEntries = []; // Clear leaderboard entries
    });
    _fetchDemoLeaderboardData(); // Fetch leaderboard based on new board year
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<AssociationModel>(
              value: _selectedAssociation,
              onChanged: _onAssociationChanged,
              dropdownColor: AppColors.lightPrimaryVariant,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: Theme.of(context).iconTheme.color),
              items: _associations.map((association) {
                return DropdownMenuItem(
                  value: association,
                  child: Text(
                    association.name,
                    style: Theme.of(context).dropdownMenuTheme.textStyle,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedAssociation != null) ...[
              Center(
                child: DropdownButton<BoardYearModel>(
                  value: _selectedBoardYear,
                  onChanged: _onBoardYearChanged,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.black),
                  items: _boardYears.map((boardYear) {
                    return DropdownMenuItem(
                      value: boardYear,
                      child: Text(boardYear.boardYear,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16.0),
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
