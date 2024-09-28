import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';
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
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  String? _selectedAssociationId;

  // Pagination variables
  final int _limit = 10;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    // Initial fetching is deferred until the association is loaded
  }

  Future<void> _fetchTransactions(String associationId,
      {bool isLoadMore = false}) async {
    setState(() {
      if (!isLoadMore) {
        _isLoading = true;
      } else {
        _isFetchingMore = true;
      }
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    try {
      // Fetch both sent and received baks by the current user in a single query
      final response = await supabase
          .from('bak_send')
          .select(
              'id, amount, status, created_at, reason, receiver_id (id, name), giver_id (id, name)')
          .or('giver_id.eq.$currentUserId,receiver_id.eq.$currentUserId') // Fetch where the current user is either the giver or the receiver
          .eq('association_id', associationId)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1); // Pagination

      setState(() {
        if (isLoadMore) {
          _transactions.addAll(List<Map<String, dynamic>>.from(response));
        } else {
          _transactions = List<Map<String, dynamic>>.from(response);
        }
        _isLoading = false;
        _isFetchingMore = false;
        _offset += _limit; // Increase the offset for the next batch
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
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
                _offset = 0; // Reset offset on association change
                _fetchTransactions(associationId);
              });
            }

            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.lightSecondary,
                    onRefresh: () {
                      _offset = 0; // Reset pagination on refresh
                      return _fetchTransactions(_selectedAssociationId!);
                    },
                    child: _buildTransactionsList(),
                  );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildTransactionsList() {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isFetchingMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _fetchTransactions(_selectedAssociationId!, isLoadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _transactions.length + (_isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final bak = _transactions[index];
          final date = DateTime.parse(bak['created_at']);
          final bakReason = bak['reason'] ?? 'No reason provided';
          final isRejected = bak['status'] == 'rejected';
          final rejectionReason = bak['reason'] ?? 'No reason provided';
          final isSent = bak['giver_id']['id'] == currentUserId;
          final recipientName = bak['receiver_id']['name'];
          final senderName = bak['giver_id']['name'];

          return ListTile(
            title: Text(
              isSent ? 'Sent to: $recipientName' : 'Received from: $senderName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: ${bak['amount']}'),
                Text('Reason: $bakReason'),
                Text(
                  'Date: ${DateFormat.yMd('nl_NL').format(date)} at ${DateFormat.Hm('nl_NL').format(date)}',
                ),
                if (isRejected)
                  Text(
                    'Rejection Reason: $rejectionReason',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
              ],
            ),
            trailing: Text(
              bak['status'].toString().toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                color: bak['status'] == 'approved'
                    ? Colors.green
                    : bak['status'] == 'declined'
                        ? Colors.red
                        : Colors.orange,
              ),
            ),
          );
        },
      ),
    );
  }
}
