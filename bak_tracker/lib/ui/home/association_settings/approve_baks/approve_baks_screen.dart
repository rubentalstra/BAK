import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/ui/home/association_settings/approve_baks/approve_bak_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class ApproveBaksScreen extends StatefulWidget {
  const ApproveBaksScreen({super.key});

  @override
  _ApproveBaksScreenState createState() => _ApproveBaksScreenState();
}

class _ApproveBaksScreenState extends State<ApproveBaksScreen> {
  List<Map<String, dynamic>> _requestedBaks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBaksFromBloc(); // Fetch initial data from the selected association
  }

  // Fetch Baks based on the current association from the Bloc
  void _fetchBaksFromBloc() {
    final associationBloc = context.read<AssociationBloc>().state;
    if (associationBloc is AssociationLoaded) {
      final associationId = associationBloc.selectedAssociation.id;
      _fetchBaks(associationId); // Use association ID from the state
    }
  }

  // Fetch Baks from the database for a specific association
  Future<void> _fetchBaks(String associationId) async {
    if (!mounted) return; // Ensure the widget is still mounted
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    try {
      // Fetch requested baks (status = 'pending') for the current association
      final requestedResponse = await supabase
          .from('bak_consumed')
          .select('id, amount, created_at, taker_id (id, name)')
          .eq('status', 'pending')
          .eq('association_id', associationId); // Use associationId filter

      if (!mounted) return; // Ensure the widget is still mounted
      setState(() {
        _requestedBaks = List<Map<String, dynamic>>.from(requestedResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching baks: $e');
      if (!mounted) return; // Ensure the widget is still mounted
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBakStatus(
      String bakId, String status, String takerId, int amount,
      [String? rejectionReason]) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    try {
      // Update the bak status in the database
      final updateData = {'status': status, 'approved_by': userId};
      if (rejectionReason != null) {
        updateData['reason'] = rejectionReason;
      }
      await supabase.from('bak_consumed').update(updateData).eq('id', bakId);

      final associationBloc = context.read<AssociationBloc>().state;
      if (associationBloc is AssociationLoaded) {
        final associationId = associationBloc.selectedAssociation.id;

        if (status == 'approved') {
          final takerResponse = await supabase
              .from('association_members')
              .select('baks_consumed')
              .eq('user_id', takerId)
              .eq('association_id', associationId)
              .single();

          final updatedConsumed = takerResponse['baks_consumed'] + amount;

          await supabase
              .from('association_members')
              .update({'baks_consumed': updatedConsumed})
              .eq('user_id', takerId)
              .eq('association_id', associationId);
        }

        // Refresh the list and badge count
        if (mounted) {
          _fetchBaks(associationId);

          // Trigger the refresh event for pending baks in the AssociationBloc
          context
              .read<AssociationBloc>()
              .add(RefreshPendingBaks(associationId));
        }

        // Insert notification for the requester
        await _insertNotification(takerId, status);
      }
    } catch (e) {
      print('Error updating bak status: $e');
    }
  }

  Future<void> _insertNotification(String userId, String status) async {
    final supabase = Supabase.instance.client;

    try {
      String title;
      String body;

      // Customize the notification message based on the status
      if (status == 'approved') {
        title = 'Bak Request Approved';
        body = 'Your bak request has been approved!';
      } else {
        title = 'Bak Request Rejected';
        body = 'Your bak request has been rejected.';
      }

      // Insert the notification into the notifications table
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
      });

      print('Notification sent to $userId');
    } catch (e) {
      print('Error inserting notification: $e');
    }
  }

  // Show dialog for rejection reason
  Future<void> _showRejectDialog(
      BuildContext context, String bakId, String takerId, int amount) async {
    final _reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Bak'),
          content: SizedBox(
            width:
                MediaQuery.of(context).size.width * 0.8, // 80% of screen width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please provide a reason for rejecting this bak:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5, // Allow for more lines
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            ElevatedButton(
              child: const Text('Reject'),
              onPressed: () {
                final reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  _updateBakStatus(bakId, 'rejected', takerId, amount, reason);
                  Navigator.of(context).pop(); // Close dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason for rejection'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssociationBloc, AssociationState>(
      builder: (context, state) {
        if (state is AssociationLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AssociationLoaded) {
          // If association is loaded, show the UI
          return Scaffold(
            appBar: AppBar(
              title: const Text('Approve Baks'),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'transactions') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProcessedBaksTransactionsScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'transactions',
                      child: Text('Go to Transactions'),
                    ),
                  ],
                ),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildRequestedTab(),
          );
        } else {
          // If no association is loaded, show error or empty state
          return const Center(child: Text('No association selected'));
        }
      },
    );
  }

  // Build the tab for requested Baks
  Widget _buildRequestedTab() {
    if (_requestedBaks.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    return ListView.builder(
      itemCount: _requestedBaks.length,
      itemBuilder: (context, index) {
        final bak = _requestedBaks[index];
        final takerName = bak['taker_id']['name']; // Fetch the taker name
        final takerId = bak['taker_id']['id']; // Fetch the taker ID
        final bakAmount = bak['amount']; // Fetch the bak amount

        return ListTile(
          title: Text('Bak Amount: ${bak['amount']}'),
          subtitle: Text('Requested by: $takerName'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () =>
                    _updateBakStatus(bak['id'], 'approved', takerId, bakAmount),
              ),
              const SizedBox(width: 8), // Add some space between the buttons
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _showRejectDialog(context, bak['id'], takerId,
                    bakAmount), // Show reject dialog
              ),
            ],
          ),
        );
      },
    );
  }
}
