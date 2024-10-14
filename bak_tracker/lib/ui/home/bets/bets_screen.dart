import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/home/bets/create_bet_tab.dart';
import 'package:bak_tracker/ui/home/bets/ongoing_bets_tab.dart';
import 'package:bak_tracker/ui/home/bets/bet_history_screen.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badges/badges.dart' as badges;
import 'package:supabase_flutter/supabase_flutter.dart';

class BetsScreen extends StatefulWidget {
  const BetsScreen({super.key});

  @override
  _BetsScreenState createState() => _BetsScreenState();
}

class _BetsScreenState extends State<BetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImageUploadService _imageUploadService =
      ImageUploadService(Supabase.instance.client);

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: BlocBuilder<AssociationBloc, AssociationState>(
            builder: (context, state) {
              int pendingBetsCount = 0;
              if (state is AssociationLoaded) {
                pendingBetsCount = state.pendingBetsCount;
              }

              return TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                tabs: [
                  const Tab(text: 'Create Bet'),
                  badges.Badge(
                    showBadge: pendingBetsCount > 0,
                    badgeContent: Text(
                      pendingBetsCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.red,
                      padding: EdgeInsets.all(6),
                    ),
                    position: badges.BadgePosition.topEnd(top: -10, end: -10),
                    child: const Tab(text: 'Ongoing Bets'),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              final state = context.read<AssociationBloc>().state;
              if (state is AssociationLoaded) {
                // Navigate to the Bet History screen with the associationId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BetHistoryScreen(
                      associationId: state.selectedAssociation.id,
                    ),
                  ),
                );
              }
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
                  associationId: associationId,
                  members: state.members,
                ),
                OngoingBetsTab(
                  associationId: associationId,
                  imageUploadService: _imageUploadService,
                ),
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
