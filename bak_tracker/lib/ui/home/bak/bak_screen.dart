import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/ui/home/bak/received_bak_tab.dart';
import 'package:bak_tracker/ui/home/bak/send_bak_tab.dart';
import 'package:bak_tracker/ui/home/bak/transactions_screen.dart';
import 'package:badges/badges.dart' as badges;
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
          BlocBuilder<AssociationBloc, AssociationState>(
            builder: (context, state) {
              if (state is AssociationLoaded) {
                final associationId = state.selectedAssociation.id;
                return IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    // Pass the associationId to the TransactionsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransactionsScreen(associationId: associationId),
                      ),
                    );
                  },
                  tooltip: 'Bak History',
                );
              }
              return const SizedBox
                  .shrink(); // In case the association isn't loaded
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: BlocBuilder<AssociationBloc, AssociationState>(
            builder: (context, state) {
              int pendingBaksCount = 0;
              if (state is AssociationLoaded) {
                pendingBaksCount = state.pendingBaksCount;
              }

              return TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                tabs: [
                  const Tab(text: 'Send Bak'),
                  badges.Badge(
                    showBadge: pendingBaksCount > 0,
                    badgeContent: Text(
                      pendingBaksCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.red,
                      padding: EdgeInsets.all(6),
                    ),
                    position: badges.BadgePosition.topEnd(top: -10, end: -10),
                    child: const Tab(text: 'Received Bak'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                SendBakTab(members: state.members),
                const ReceivedBakTab(),
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
