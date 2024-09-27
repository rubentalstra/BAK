import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
      return _buildLoadingSkeleton();
    }

    if (_ongoingBets.isEmpty) {
      return const Center(child: Text('No ongoing bets.'));
    }

    return ListView.builder(
      itemCount: _ongoingBets.length,
      itemBuilder: (context, index) {
        final bet = _ongoingBets[index];
        return ListTile(
          title: Text('Bet: ${bet['amount']} bakken'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${bet['bet_description']}'),
              Text('Status: ${bet['status']}'),
              if (bet['status'] == 'pending')
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _updateBetStatus(bet['id'], 'accepted'),
                      child: const Text('Accept'),
                    ),
                    TextButton(
                      onPressed: () => _updateBetStatus(bet['id'], 'rejected'),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              if (bet['status'] == 'accepted')
                Row(
                  children: [
                    DropdownButton<String>(
                      hint: const Text('Select Winner'),
                      items: [
                        DropdownMenuItem<String>(
                          value: bet['bet_creator_id'],
                          child: Text('Bet Creator'),
                        ),
                        DropdownMenuItem<String>(
                          value: bet['bet_receiver_id'],
                          child: Text('Bet Receiver'),
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
                ),
            ],
          ),
        );
      },
    );
  }

  // Loading skeleton for ongoing bets
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Skeletonizer(
            effect: const ShimmerEffect(
              baseColor: Color(0xFFE0E0E0),
              highlightColor: Color(0xFFF5F5F5),
              duration: Duration(seconds: 1),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24.0,
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16.0,
                          width: 100.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Container(
                          height: 14.0,
                          width: 150.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
