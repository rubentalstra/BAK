import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class BetHistoryScreen extends StatefulWidget {
  const BetHistoryScreen({super.key});

  @override
  _BetHistoryScreenState createState() => _BetHistoryScreenState();
}

class _BetHistoryScreenState extends State<BetHistoryScreen> {
  List<Map<String, dynamic>> _betHistory = [];
  bool _isLoading = true;
  String? _selectedAssociationId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchBetHistory(String associationId) async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    try {
      // Fetch settled bets (status = 'settled') for the current association
      final betHistoryResponse = await supabase
          .from('bets')
          .select(
              'id, amount, status, bet_creator_id (id, name), bet_receiver_id (id, name), bet_description, winner_id, created_at')
          .eq('status', 'settled')
          .eq('association_id', associationId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _betHistory = List<Map<String, dynamic>>.from(betHistoryResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bet history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bet History'),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            final associationId = state.selectedAssociation.id;
            if (_selectedAssociationId != associationId) {
              _selectedAssociationId = associationId;

              // Fetch bet history only when the association changes or on first load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchBetHistory(associationId);
              });
            }

            return RefreshIndicator(
              color: AppColors.lightSecondary,
              onRefresh: () => _fetchBetHistory(associationId),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBetHistoryList(),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildBetHistoryList() {
    if (_betHistory.isEmpty) {
      return const Center(child: Text('No settled bets found'));
    }

    return ListView.builder(
      itemCount: _betHistory.length,
      itemBuilder: (context, index) {
        final bet = _betHistory[index];
        final creatorName = bet['bet_creator_id']['name'];
        final receiverName = bet['bet_receiver_id']['name'];
        final betDescription = bet['bet_description'];
        final winnerId = bet['winner_id'];
        final winnerName = winnerId == bet['bet_creator_id']['id']
            ? creatorName
            : receiverName;
        final amount = bet['amount'];
        final createdAt = DateTime.parse(bet['created_at']).toLocal();
        final formattedDate =
            '${createdAt.day}/${createdAt.month}/${createdAt.year}';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Bet between $creatorName and $receiverName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount: $amount bakken',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Winner: $winnerName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Description: $betDescription'),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Date: $formattedDate',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),
            ],
          ),
        );
      },
    );
  }
}
