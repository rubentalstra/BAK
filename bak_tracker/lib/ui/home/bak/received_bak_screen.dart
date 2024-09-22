import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class ReceivedBakScreen extends StatefulWidget {
  const ReceivedBakScreen({super.key});

  @override
  _ReceivedBakScreenState createState() => _ReceivedBakScreenState();
}

class _ReceivedBakScreenState extends State<ReceivedBakScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _receivedBakken = [];
  bool _isLoadingReceived = false;
  String? _selectedAssociationId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchReceivedBakken(String associationId) async {
    setState(() {
      _isLoadingReceived = true;
    });

    final supabase = Supabase.instance.client;

    // Fetch received bakken for the specific association
    final response = await supabase
        .from('bak_send')
        .select(
            'id, amount, status, created_at, receiver_id (id, name), giver_id (id, name), association_id')
        .eq('receiver_id', Supabase.instance.client.auth.currentUser!.id)
        .eq('association_id', associationId) // Filter by association_id
        .eq('status', 'pending') // Only fetch 'pending' baks
        .order('created_at', ascending: false);

    setState(() {
      _receivedBakken = List<Map<String, dynamic>>.from(response);
      _isLoadingReceived = false;
    });
  }

  // Approve Bak
  Future<void> approveBak(String bakId, int amount, String receiverId,
      String giverId, String associationId) async {
    final supabase = Supabase.instance.client;

    try {
      // Update the bak_send table to mark the bak as approved
      await supabase
          .from('bak_send')
          .update({'status': 'approved'}).eq('id', bakId);

      // Get the current baks_received value for the receiver filtered by association_id
      final receiverResponse = await supabase
          .from('association_members')
          .select('baks_received')
          .eq('user_id', receiverId)
          .eq('association_id', associationId) // Filter by association_id
          .single();

      if (receiverResponse['baks_received'] != null) {
        // Increment the baks_received value
        final updatedBaksReceived = receiverResponse['baks_received'] + amount;

        // Update the baks_received for the receiver filtered by association_id
        await supabase
            .from('association_members')
            .update({
              'baks_received': updatedBaksReceived,
            })
            .eq('user_id', receiverId)
            .eq('association_id', associationId); // Filter by association_id
      }

      // Refresh the data
      _fetchReceivedBakken(associationId);
    } catch (e) {
      print('Error approving bak: $e');
    }
  }

  // Decline Bak
  Future<void> declineBak(
      String bakId, int amount, giverId, String associationId) async {
    final supabase = Supabase.instance.client;

    try {
      // Update the bak_send table to mark the bak as declined
      await supabase
          .from('bak_send')
          .update({'status': 'declined'}).eq('id', bakId);

      // Get the current baks_consumed value for the giver filtered by association_id
      final giverResponse = await supabase
          .from('association_members')
          .select('baks_consumed')
          .eq('user_id', giverId)
          .eq('association_id', associationId) // Filter by association_id
          .single();

      if (giverResponse['baks_consumed'] != null) {
        // Increment the baks_consumed value
        final updatedBaksConsumed = giverResponse['baks_consumed'] + amount;

        // Update the baks_consumed for the giver filtered by association_id
        await supabase
            .from('association_members')
            .update({
              'baks_consumed': updatedBaksConsumed,
            })
            .eq('user_id', giverId)
            .eq('association_id', associationId); // Filter by association_id
      }

      // Refresh the data
      _fetchReceivedBakken(associationId);
    } catch (e) {
      print('Error declining bak: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssociationBloc, AssociationState>(
      builder: (context, state) {
        if (state is AssociationLoaded) {
          final associationId = state.selectedAssociation.id;
          if (_selectedAssociationId != associationId) {
            _selectedAssociationId = associationId;

            // Fetch transactions only when the association changes or on first load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchReceivedBakken(associationId);
            });
          }

          return _isLoadingReceived
              ? const Center(child: CircularProgressIndicator())
              : _receivedBakken.isEmpty
                  ? const Center(child: Text('No pending baks found.'))
                  : ListView.builder(
                      itemCount: _receivedBakken.length,
                      itemBuilder: (context, index) {
                        final bak = _receivedBakken[index];
                        final date =
                            DateTime.parse(bak['created_at']).toLocal();
                        final formattedDate =
                            '${date.day}/${date.month}/${date.year}';

                        return ListTile(
                          title:
                              Text('Received from: ${bak['giver_id']['name']}'),
                          subtitle: Text(
                              'Amount: ${bak['amount']} | Date: $formattedDate'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => approveBak(
                                  bak['id'],
                                  bak['amount'],
                                  bak['receiver_id']['id'],
                                  bak['giver_id']['id'],
                                  bak['association_id'], // Pass association_id
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => declineBak(
                                  bak['id'],
                                  bak['amount'],
                                  bak['giver_id']['id'],
                                  bak['association_id'], // Pass association_id
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
