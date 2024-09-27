import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OngoingBetsTab extends StatefulWidget {
  final String associationId;

  const OngoingBetsTab({
    Key? key,
    required this.associationId,
  }) : super(key: key);

  @override
  _OngoingBetsTabState createState() => _OngoingBetsTabState();
}

class _OngoingBetsTabState extends State<OngoingBetsTab> {
  List<Map<String, dynamic>> _ongoingBets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOngoingBets(); // Fetch bets when the tab is opened
  }

  Future<void> _fetchOngoingBets() async {
    final supabase = Supabase.instance.client;
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await supabase
          .from('bets')
          .select()
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

  Future<void> _updateBetStatus(String betId, String newStatus) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('bets').update({'status': newStatus}).eq('id', betId);
      _fetchOngoingBets(); // Refresh the bet list after update
    } catch (e) {
      print('Error updating bet status: $e');
    }
  }

  Future<void> _settleBet(
      String betId, String winnerId, String loserId, int amount) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('bets')
          .update({'status': 'settled', 'winner_id': winnerId}).eq('id', betId);

      final loserResponse = await supabase
          .from('association_members')
          .select('baks_received')
          .eq('user_id', loserId)
          .eq('association_id', widget.associationId)
          .single();

      final updatedBaksReceived = loserResponse['baks_received'] + amount;

      await supabase
          .from('association_members')
          .update({'baks_received': updatedBaksReceived})
          .eq('user_id', loserId)
          .eq('association_id', widget.associationId);

      _fetchOngoingBets(); // Refresh the bet list after settlement
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
                _buildStatusIndicator(bet['status']),
                const SizedBox(height: 8),
                if (bet['status'] == 'pending') _buildPendingActions(bet),
                if (bet['status'] == 'accepted') _buildWinnerSelection(bet),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget for bet status
  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    String statusText;

    if (status == 'pending') {
      statusColor = Colors.orange;
      statusText = 'Pending Approval';
    } else if (status == 'accepted') {
      statusColor = Colors.green;
      statusText = 'Accepted - Ready to Settle';
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown Status';
    }

    return Row(
      children: [
        Icon(
          Icons.circle,
          color: statusColor,
          size: 12,
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  // Widget for pending actions (Accept/Reject)
  Widget _buildPendingActions(Map<String, dynamic> bet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _updateBetStatus(bet['id'], 'accepted'),
          child: const Text(
            'Accept',
            style: TextStyle(color: Colors.green),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _updateBetStatus(bet['id'], 'rejected'),
          child: const Text(
            'Reject',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  // Widget for selecting the winner (after the bet is accepted)
  Widget _buildWinnerSelection(Map<String, dynamic> bet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Select Winner:'),
        DropdownButton<String>(
          hint: const Text('Choose'),
          items: [
            DropdownMenuItem<String>(
              value: bet['bet_creator_id'],
              child: const Text('Bet Creator'),
            ),
            DropdownMenuItem<String>(
              value: bet['bet_receiver_id'],
              child: const Text('Bet Receiver'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              final loserId = value == bet['bet_creator_id']
                  ? bet['bet_receiver_id']
                  : bet['bet_creator_id'];
              _settleBet(bet['id'], value, loserId, bet['amount']);
            }
          },
        ),
      ],
    );
  }
}
