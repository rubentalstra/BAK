import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/bak_send_model.dart';
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
  List<BakSendModel> _transactions = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  String? _selectedAssociationId;

  // Pagination variables
  final int _limit = 10; // Number of items to fetch at a time
  int _offset = 0; // Offset to keep track of how much data has been fetched
  bool _hasMoreData = true; // To check if more data is available

  @override
  void initState() {
    super.initState();
    // Initial fetching is deferred until the association is loaded
  }

  Future<void> _fetchTransactions(String associationId,
      {bool isLoadMore = false}) async {
    if (_isFetchingMore || !_hasMoreData) {
      return; // Prevent multiple fetches or fetching when no more data is available
    }

    setState(() {
      if (!isLoadMore) {
        _isLoading = true;
      } else {
        _isFetchingMore = true;
      }
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      return; // Handle null user ID case
    }

    try {
      // Fetch the transactions with pagination
      final response = await supabase
          .from('bak_send')
          .select(
              'id, association_id, amount, status, created_at, reason, receiver_id (id, name), giver_id (id, name)')
          .or('giver_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('association_id', associationId)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1); // Pagination

      final List<BakSendModel> fetchedTransactions =
          (response as List).map((map) => BakSendModel.fromMap(map)).toList();

      setState(() {
        if (isLoadMore) {
          _transactions.addAll(fetchedTransactions);
        } else {
          _transactions = fetchedTransactions;
        }

        // Check if more data is available
        if (fetchedTransactions.length < _limit) {
          _hasMoreData =
              false; // No more data if less than the limit is returned
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
      _showErrorSnackBar('Failed to load transactions. Please try again.');
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

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _resetPagination(); // Reset pagination when association changes
                _fetchTransactions(associationId);
              });
            }

            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.lightSecondary,
                    onRefresh: () {
                      _resetPagination(); // Reset pagination on refresh
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

  // Build the list of transactions with pagination
  Widget _buildTransactionsList() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isFetchingMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            _hasMoreData) {
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
          return _buildTransactionTile(bak, currentUserId!);
        },
      ),
    );
  }

  // Build individual transaction tile using BakSendModel
  Widget _buildTransactionTile(BakSendModel bak, String currentUserId) {
    final isSent = bak.giver.id == currentUserId;
    final recipientName = bak.receiver.name;
    final senderName = bak.giver.name;

    return ListTile(
      title: Text(
        isSent ? 'Sent to: $recipientName' : 'Received from: $senderName',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount: ${bak.amount}'),
          Text('Reason: ${bak.reason ?? 'No reason provided'}'),
          Text(
            'Date: ${DateFormat.yMd('nl_NL').format(bak.createdAt)} at ${DateFormat.Hm('nl_NL').format(bak.createdAt)}',
          ),
          if (bak.status == 'rejected')
            Text(
              'Rejection Reason: ${bak.reason}',
              style: const TextStyle(color: Colors.redAccent),
            ),
        ],
      ),
      trailing: _buildTransactionStatus(bak.status),
    );
  }

  // Build status widget for each transaction
  Widget _buildTransactionStatus(String status) {
    return Text(
      status.toUpperCase(),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: _getStatusColor(status),
      ),
    );
  }

  // Get the status color based on the transaction status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Reset the pagination variables when switching associations or refreshing
  void _resetPagination() {
    _offset = 0;
    _hasMoreData = true;
    _transactions.clear();
  }

  // Show error snackbar in case of failure
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
