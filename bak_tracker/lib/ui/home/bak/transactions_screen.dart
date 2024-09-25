import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _sentBakken = [];
  List<Map<String, dynamic>> _receivedBakkenTransaction = [];
  bool _isLoading = true;
  String? _selectedAssociationId;

  @override
  void initState() {
    super.initState();
    // Initial fetching is deferred until the association is loaded
  }

  Future<void> _fetchTransactions(String associationId) async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    try {
      // Fetch sent baks by the current user
      final sentResponse = await supabase
          .from('bak_send')
          .select(
              'id, amount, status, created_at, reason, receiver_id (id, name), giver_id (id, name)')
          .eq('giver_id', currentUserId)
          .eq('association_id', associationId)
          .neq('status', 'pending')
          .order('created_at', ascending: false);

      // Fetch received baks by the current user (excluding pending ones)
      final receivedResponse = await supabase
          .from('bak_send')
          .select(
              'id, amount, status, created_at, reason, receiver_id (id, name), giver_id (id, name)')
          .eq('receiver_id', currentUserId)
          .eq('association_id', associationId)
          .neq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        _sentBakken = List<Map<String, dynamic>>.from(sentResponse);
        _receivedBakkenTransaction =
            List<Map<String, dynamic>>.from(receivedResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            final associationId = state.selectedAssociation.id;
            if (_selectedAssociationId != associationId) {
              _selectedAssociationId = associationId;

              // Fetch transactions only when the association changes or on first load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchTransactions(associationId);
              });
            }

            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTransactionsList();
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // Build the list of transactions (combined sent and received baks)
  Widget _buildTransactionsList() {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    // Combine sent and received baks into a single list
    List<Map<String, dynamic>> transactions = [
      ..._sentBakken,
      ..._receivedBakkenTransaction
    ];
    transactions.sort((a, b) => DateTime.parse(b['created_at'])
        .compareTo(DateTime.parse(a['created_at']))); // Sort by newest first

    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final bak = transactions[index];
        final date = DateTime.parse(bak['created_at']);

        // Check if the current user sent or received the bak
        final isSent = bak['giver_id']['id'] == currentUserId;

        return ListTile(
          title: Text(
            isSent
                ? 'Sent to: ${bak['receiver_id']['name']}'
                : 'Received from: ${bak['giver_id']['name']}',
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ${bak['amount']}'),
              Text('Reason: ${bak['reason']}'), // Add the reason field
              Text(
                  'Date: ${DateFormat.yMd('nl_NL').format(date)} ${DateFormat.Hm('nl_NL').format(date)}'),
            ],
          ),
          trailing: Text('Status: ${bak['status']}'),
        );
      },
    );
  }
}
