import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/models/bak_send_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReceivedBakTab extends StatefulWidget {
  const ReceivedBakTab({super.key});

  @override
  _ReceivedBakTabState createState() => _ReceivedBakTabState();
}

class _ReceivedBakTabState extends State<ReceivedBakTab> {
  List<BakSendModel> _receivedBakken = [];
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
              : _receivedBakken.isEmpty
                  ? _buildEmptyState()
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

    try {
      final response = await supabase
          .from('bak_send')
          .select(
              'id, amount, status, created_at, reason, decline_reason, receiver_id (id, name), giver_id (id, name), association_id')
          .eq('receiver_id', supabase.auth.currentUser!.id)
          .eq('association_id', associationId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        _receivedBakken =
            (response as List).map((map) => BakSendModel.fromMap(map)).toList();

        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Error fetching baks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No pending baks received',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedBakkenList() {
    return ListView.builder(
      itemCount: _receivedBakken.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final bak = _receivedBakken[index];
        final formattedDate = DateFormat('dd/MM/yyyy').format(bak.createdAt);

        return _buildBakCard(bak, formattedDate);
      },
    );
  }

  Widget _buildBakCard(BakSendModel bak, String formattedDate) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Information
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.user,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Received from: ${bak.giver.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Amount and Date
            Row(
              children: [
                const Icon(Icons.local_drink, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Amount: ${bak.amount}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  'Date: $formattedDate',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reason for the bak
            Row(
              children: [
                const Icon(Icons.description, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reason: ${bak.reason ?? 'No reason provided'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (bak.status == 'declined')
              Row(
                children: [
                  const Icon(Icons.error, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Decline Reason: ${bak.declineReason ?? 'No reason provided'}',
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Approval and Decline Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveBak(bak),
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _showDeclineDialog(bak),
                  tooltip: 'Decline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveBak(BakSendModel bak) async {
    final supabase = Supabase.instance.client;
    final associationId = bak.associationId;

    try {
      await supabase
          .from('bak_send')
          .update({'status': 'approved'}).eq('id', bak.id);

      await _incrementReceivedBaks(bak.receiver.id, bak.amount, associationId);

      context.read<AssociationBloc>().add(RefreshBaksAndBets(associationId));

      _fetchReceivedBakken(associationId);
    } catch (e) {
      print('Error approving bak: $e');
    }
  }

  Future<void> _showDeclineDialog(BakSendModel bak) async {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decline Bak'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for declining',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  _declineBak(bak, reasonController.text);
                  Navigator.of(context).pop();
                } else {
                  _showSnackBar('Please enter a reason for declining.');
                }
              },
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _declineBak(BakSendModel bak, String declineReason) async {
    final supabase = Supabase.instance.client;
    final associationId = bak.associationId;

    try {
      await supabase
          .from('bak_send')
          .update({'status': 'declined', 'decline_reason': declineReason}).eq(
              'id', bak.id);

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

  // Consolidated snack bar method
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
