import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/services/bak_service.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/home/bets/widgets/bet_participants.dart';
import 'package:bak_tracker/ui/home/bets/widgets/pending_actions.dart';
import 'package:bak_tracker/ui/home/bets/widgets/status_indicator.dart';
import 'package:bak_tracker/ui/home/bets/widgets/winner_selection.dart';

class OngoingBetsTab extends StatefulWidget {
  final String associationId;
  final ImageUploadService imageUploadService;

  const OngoingBetsTab({
    super.key,
    required this.associationId,
    required this.imageUploadService,
  });

  @override
  _OngoingBetsTabState createState() => _OngoingBetsTabState();
}

class _OngoingBetsTabState extends State<OngoingBetsTab> {
  List<Map<String, dynamic>> _ongoingBets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOngoingBets();
  }

  Future<void> _fetchOngoingBets() async {
    final supabase = Supabase.instance.client;
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await supabase
          .from('bets')
          .select(
              'id, bet_creator_id(id, name, profile_image), bet_receiver_id(id, name, profile_image), amount, bet_description, status, association_id')
          .eq('association_id', widget.associationId)
          .inFilter('status', ['pending', 'accepted']).order('created_at',
              ascending: false);

      setState(() {
        _ongoingBets = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching ongoing bets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBetStatus(
      String betId, String newStatus, String creatorId) async {
    final receiverId = Supabase.instance.client.auth.currentUser!.id;

    try {
      await BakService.updateBetStatus(
        betId: betId,
        newStatus: newStatus,
        receiverId: receiverId,
        creatorId: creatorId,
      );
      _fetchOngoingBets();
    } catch (e) {
      print('Error updating bet status: $e');
    }
  }

  Future<void> _settleBet(
      String betId, String winnerId, String loserId, int amount) async {
    try {
      await BakService.settleBet(
        betId: betId,
        winnerId: winnerId,
        loserId: loserId,
        amount: amount,
        associationId: widget.associationId,
      );
      _fetchOngoingBets();
    } catch (e) {
      print('Error settling bet: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ongoingBets.isEmpty) {
      return const Center(child: Text('No ongoing bets.'));
    }

    return ListView.builder(
      itemCount: _ongoingBets.length,
      itemBuilder: (context, index) {
        final bet = _ongoingBets[index];
        final currentUserId = Supabase.instance.client.auth.currentUser!.id;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BetParticipants(
                  bet: bet,
                  imageUploadService: widget.imageUploadService,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bet: ${bet['amount']} bakken',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Description: ${bet['bet_description']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                StatusIndicator(status: bet['status']),
                const SizedBox(height: 8),
                if (bet['status'] == 'pending' &&
                    bet['bet_receiver_id']['id'] == currentUserId)
                  PendingActions(
                    bet: bet,
                    onUpdateBetStatus: _updateBetStatus,
                  ),
                if (bet['status'] == 'accepted')
                  WinnerSelection(
                    bet: bet,
                    onWinnerSelected: _handleWinnerSelection,
                    imageUploadService: widget.imageUploadService,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleWinnerSelection(
      Map<String, dynamic> bet, String selectedWinnerId) {
    final loserId = selectedWinnerId == bet['bet_creator_id']['id']
        ? bet['bet_receiver_id']['id']
        : bet['bet_creator_id']['id'];
    _settleBet(bet['id'], selectedWinnerId, loserId, bet['amount']);
  }
}
