import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/home/bets/create_bet_tab.dart';
import 'package:bak_tracker/ui/home/bets/ongoing_bets_tab.dart';
import 'package:bak_tracker/ui/home/bets/bet_history_screen.dart'; // Import for Bet History
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BetsScreen extends StatefulWidget {
  const BetsScreen({Key? key}) : super(key: key);

  @override
  _BetsScreenState createState() => _BetsScreenState();
}

class _BetsScreenState extends State<BetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bets'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create Bet'),
            Tab(text: 'Ongoing Bets'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to the Bet History screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BetHistoryScreen(),
                ),
              );
            },
            tooltip: 'Bet History',
          ),
        ],
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            final associationId = state.selectedAssociation.id;

            return TabBarView(
              controller: _tabController,
              children: [
                CreateBetTab(
                    associationId: associationId, members: state.members),
                OngoingBetsTab(associationId: associationId),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
