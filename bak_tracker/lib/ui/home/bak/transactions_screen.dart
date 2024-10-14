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
  bool _hasMoreData = true;
  final int _limit = 10;
  int _offset = 0;
  final ScrollController _scrollController = ScrollController();
  String _selectedAssociationId = ''; // Initialize with an empty string

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isFetchingMore &&
        _hasMoreData) {
      _fetchTransactions(isLoadMore: true);
    }
  }

  Future<void> _fetchTransactions({bool isLoadMore = false}) async {
    // Make sure the association ID is not empty before fetching
    if (_isFetchingMore || !_hasMoreData || _selectedAssociationId.isEmpty) {
      return;
    }

    setState(() {
      if (isLoadMore) {
        _isFetchingMore = true;
      } else {
        _isLoading = true;
        _offset = 0;
        _hasMoreData = true;
        _transactions.clear();
      }
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final response = await supabase
          .from('bak_send')
          .select(
              'id, association_id, amount, status, created_at, reason, receiver_id (id, name), giver_id (id, name), decline_reason')
          .or('giver_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('association_id', _selectedAssociationId)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      final List<BakSendModel> fetchedTransactions =
          (response as List).map((map) => BakSendModel.fromMap(map)).toList();

      setState(() {
        if (isLoadMore) {
          _transactions.addAll(fetchedTransactions);
        } else {
          _transactions = fetchedTransactions;
        }

        if (fetchedTransactions.length < _limit) {
          _hasMoreData = false;
        }

        _isLoading = false;
        _isFetchingMore = false;
        _offset += _limit;
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

  Future<void> _refreshTransactions() async {
    _resetPagination();
    await _fetchTransactions();
  }

  void _resetPagination() {
    _offset = 0;
    _hasMoreData = true;
    _transactions.clear();
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
                _resetPagination();
                _fetchTransactions();
              });
            }

            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.lightSecondary,
                    onRefresh: _refreshTransactions,
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
    if (_transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions found.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _transactions.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _transactions.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final bak = _transactions[index];
        return _buildTransactionCard(bak);
      },
    );
  }

  Widget _buildTransactionCard(BakSendModel bak) {
    final isSent =
        bak.giver.id == Supabase.instance.client.auth.currentUser?.id;
    final recipientName = bak.receiver.name;
    final senderName = bak.giver.name;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightPrimary,
                  radius: 24,
                  child: Icon(
                    isSent ? Icons.send : Icons.inbox,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSent
                        ? 'Sent to: $recipientName'
                        : 'Received from: $senderName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  bak.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(bak.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${bak.amount}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Reason: ${bak.reason ?? 'No reason provided'}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Date: ${DateFormat.yMMMd('nl_NL').format(bak.createdAt)} at ${DateFormat.Hm('nl_NL').format(bak.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (bak.status == 'declined')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Declined Reason: ${bak.declineReason ?? 'No reason provided'}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
