import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class ReceivedBakTab extends StatefulWidget {
  const ReceivedBakTab({super.key});

  @override
  _ReceivedBakTabState createState() => _ReceivedBakTabState();
}

class _ReceivedBakTabState extends State<ReceivedBakTab> {
  List<Map<String, dynamic>> _receivedBakken = [];
  bool _isLoading = false;
  String? _selectedAssociationId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssociationBloc, AssociationState>(
      builder: (context, state) {
        if (state is AssociationLoaded) {
          final associationId = state.selectedAssociation.id;
          if (_selectedAssociationId != associationId) {
            _selectedAssociationId = associationId;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchReceivedBakken(associationId);
            });
          }

          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildReceivedBakkenList();
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<void> _fetchReceivedBakken(String associationId) async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('bak_send')
        .select(
            'id, amount, status, created_at, receiver_id (id, name), giver_id (id, name), association_id')
        .eq('receiver_id', supabase.auth.currentUser!.id)
        .eq('association_id', associationId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    setState(() {
      _receivedBakken = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  Widget _buildReceivedBakkenList() {
    if (_receivedBakken.isEmpty) {
      return const Center(child: Text('No pending baks found.'));
    }

    return ListView.builder(
      itemCount: _receivedBakken.length,
      itemBuilder: (context, index) {
        final bak = _receivedBakken[index];
        final date = DateTime.parse(bak['created_at']).toLocal();
        final formattedDate = '${date.day}/${date.month}/${date.year}';

        return ListTile(
          title: Text('Received from: ${bak['giver_id']['name']}'),
          subtitle: Text('Amount: ${bak['amount']} | Date: $formattedDate'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _approveBak(bak),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _declineBak(bak),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _approveBak(Map<String, dynamic> bak) async {
    final supabase = Supabase.instance.client;
    final associationId = bak['association_id'];

    try {
      await supabase
          .from('bak_send')
          .update({'status': 'approved'}).eq('id', bak['id']);

      await _incrementReceivedBaks(
          bak['receiver_id']['id'], bak['amount'], associationId);

      context.read<AssociationBloc>().add(RefreshBaksAndBets(associationId));

      _fetchReceivedBakken(associationId);
    } catch (e) {
      print('Error approving bak: $e');
    }
  }

  Future<void> _declineBak(Map<String, dynamic> bak) async {
    final supabase = Supabase.instance.client;
    final associationId = bak['association_id'];

    try {
      await supabase
          .from('bak_send')
          .update({'status': 'declined'}).eq('id', bak['id']);

      context.read<AssociationBloc>().add(RefreshBaksAndBets(associationId));

      _fetchReceivedBakken(associationId);
    } catch (e) {
      print('Error declining bak: $e');
    }
  }

  Future<void> _incrementReceivedBaks(
      String receiverId, int amount, String associationId) async {
    final supabase = Supabase.instance.client;

    final receiverResponse = await supabase
        .from('association_members')
        .select('baks_received')
        .eq('user_id', receiverId)
        .eq('association_id', associationId)
        .single();

    if (receiverResponse['baks_received'] != null) {
      final updatedBaksReceived = receiverResponse['baks_received'] + amount;

      await supabase
          .from('association_members')
          .update({'baks_received': updatedBaksReceived})
          .eq('user_id', receiverId)
          .eq('association_id', associationId);
    }
  }
}
