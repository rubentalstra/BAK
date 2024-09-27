import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class ChuckedTransactionsScreen extends StatefulWidget {
  const ChuckedTransactionsScreen({super.key});

  @override
  _ChuckedTransactionsScreenState createState() =>
      _ChuckedTransactionsScreenState();
}

class _ChuckedTransactionsScreenState extends State<ChuckedTransactionsScreen> {
  List<Map<String, dynamic>> _chuckedBakken = [];
  bool _isLoading = true;
  String? _selectedAssociationId;

  @override
  void initState() {
    super.initState();
    // Initial fetching is deferred until the association is loaded
  }

  Future<void> _fetchChuckedTransactions(String associationId) async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    try {
      // Fetch chucked bakken transactions (those consumed by the current user)
      final chuckedResponse = await supabase
          .from('bak_consumed')
          .select(
              'id, amount, status, created_at, association_id, reason, taker_id (id, name)')
          .eq('taker_id', currentUserId)
          .eq('association_id', associationId)
          .order('created_at', ascending: false);

      setState(() {
        _chuckedBakken = List<Map<String, dynamic>>.from(chuckedResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching chucked transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chucked Transactions'),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            final associationId = state.selectedAssociation.id;
            if (_selectedAssociationId != associationId) {
              _selectedAssociationId = associationId;

              // Fetch chucked transactions only when the association changes or on first load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchChuckedTransactions(associationId);
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

// Build the list of chucked transactions
  Widget _buildTransactionsList() {
    if (_chuckedBakken.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return ListView.builder(
      itemCount: _chuckedBakken.length,
      itemBuilder: (context, index) {
        final bak = _chuckedBakken[index];
        final date = DateTime.parse(bak['created_at']);

        // Check if the bak status is 'rejected' and get the reason if available
        final isRejected = bak['status'] == 'rejected';
        final rejectionReason = bak['reason'] ??
            'No reason provided'; // Assuming 'reason' field exists

        return ListTile(
          title: Text(
            'Amount: ${bak['amount']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${DateFormat.yMd('nl_NL').format(date)} at ${DateFormat.Hm('nl_NL').format(date)}',
              ),
              if (isRejected) ...[
                const SizedBox(height: 4), // Spacing between date and reason
                Text(
                  'Rejection Reason: $rejectionReason',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ]
            ],
          ),
          trailing: Text(
            bak['status'],
            style: TextStyle(
                color: bak['status'] == 'approved'
                    ? Colors.green
                    : bak['status'] == 'rejected'
                        ? Colors.red
                        : Colors.grey),
          ),
        );
      },
    );
  }
}
