import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/ui/home/bak/received_bak_tab.dart';
import 'package:bak_tracker/ui/home/bak/send_bak_tab.dart';
import 'package:bak_tracker/ui/home/bak/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class BakScreen extends StatefulWidget {
  const BakScreen({super.key});

  @override
  _BakScreenState createState() => _BakScreenState();
}

class _BakScreenState extends State<BakScreen>
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
        title: const Text('Bak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to the Bet History screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionsScreen(),
                ),
              );
            },
            tooltip: 'Bak History',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send Bak'),
            Tab(text: 'Received Bak'),
          ],
        ),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                SendBakTab(members: state.members), // Modularized Send Bak Tab
                const ReceivedBakTab(), // Already exists
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
