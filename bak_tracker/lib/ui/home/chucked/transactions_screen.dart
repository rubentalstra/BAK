import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/core/utils/scroll_pagination_controller.dart';
import 'package:bak_tracker/models/bak_consumed_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChuckedTransactionsScreen extends StatefulWidget {
  final String associationId;

  const ChuckedTransactionsScreen({super.key, required this.associationId});

  @override
  _ChuckedTransactionsScreenState createState() =>
      _ChuckedTransactionsScreenState();
}

class _ChuckedTransactionsScreenState extends State<ChuckedTransactionsScreen> {
  final List<BakConsumedModel> _chuckedBakken = [];
  final ScrollPaginationController _scrollPaginationController =
      ScrollPaginationController();

  @override
  void initState() {
    super.initState();
    _scrollPaginationController.initScrollListener(_loadMore);
    _fetchChuckedTransactions(); // Fetch on first load
  }

  @override
  void dispose() {
    _scrollPaginationController.dispose();
    super.dispose();
  }

  Future<void> _fetchChuckedTransactions({bool isLoadMore = false}) async {
    if (_scrollPaginationController.isFetchingMore ||
        !_scrollPaginationController.hasMoreData) return;

    if (isLoadMore) {
      setState(() {
        _scrollPaginationController.setFetchingMore(true);
      });
    } else {
      setState(() {
        _scrollPaginationController.setLoading(true);
        _chuckedBakken.clear();
        _scrollPaginationController.resetPagination();
      });
    }

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    try {
      final chuckedResponse = await supabase
          .from('bak_consumed')
          .select(
              'id, amount, status, created_at, association_id, reason, approved_by (id, name), taker_id (id, name)')
          .eq('taker_id', currentUserId)
          .eq('association_id',
              widget.associationId) // Use the passed associationId
          .order('created_at', ascending: false)
          .range(
              _scrollPaginationController.offset,
              _scrollPaginationController.offset +
                  _scrollPaginationController.limit -
                  1);

      if (!mounted) return;

      final List<BakConsumedModel> chuckedBakkenList = chuckedResponse
          .map<BakConsumedModel>((data) => BakConsumedModel.fromMap(data))
          .toList();

      setState(() {
        if (chuckedBakkenList.length < _scrollPaginationController.limit) {
          _scrollPaginationController.setHasMoreData(false);
        }

        _chuckedBakken.addAll(chuckedBakkenList);
        _scrollPaginationController.setLoading(false);
        _scrollPaginationController.setFetchingMore(false);
        _scrollPaginationController.incrementOffset();
      });
    } catch (e) {
      print('Error fetching chucked transactions: $e');
      setState(() {
        _scrollPaginationController.setLoading(false);
        _scrollPaginationController.setFetchingMore(false);
      });
    }
  }

  void _loadMore() async {
    await _fetchChuckedTransactions(isLoadMore: true);
  }

  Future<void> _refreshTransactions() async {
    await _fetchChuckedTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chucked Transactions'),
      ),
      body: RefreshIndicator(
        color: AppColors.lightSecondary,
        onRefresh: _refreshTransactions,
        child: _scrollPaginationController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chuckedBakken.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : _buildTransactionsList(),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      controller: _scrollPaginationController.scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _chuckedBakken.length +
          (_scrollPaginationController.isFetchingMore ||
                  !_scrollPaginationController.hasMoreData
              ? 1
              : 0),
      itemBuilder: (context, index) {
        if (index == _chuckedBakken.length) {
          if (_scrollPaginationController.isFetchingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!_scrollPaginationController.hasMoreData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text('No more data to load')),
            );
          }

          return const SizedBox.shrink();
        }

        return _buildTransactionCard(_chuckedBakken[index]);
      },
    );
  }

  Widget _buildTransactionCard(BakConsumedModel bak) {
    final isRejected = bak.status == 'rejected';
    final rejectionReason = bak.reason ?? 'No reason provided';
    final approvedBy = bak.approvedBy?.name;
    final formattedDate = DateFormat.yMMMd('nl_NL').format(bak.createdAt);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(bak),
            const SizedBox(height: 8),
            _buildAmountRow(bak.amount),
            const SizedBox(height: 8),
            _buildDateRow(formattedDate),
            if (isRejected) _buildRejectionRow(rejectionReason),
            if (bak.status == 'approved') _buildApprovalRow(approvedBy),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(BakConsumedModel bak) {
    return Row(
      children: [
        const Icon(
          Icons.person,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Requested by: ${bak.taker.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(int amount) {
    return Row(
      children: [
        const Icon(FontAwesomeIcons.beerMugEmpty, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          'Bakken: $amount',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDateRow(String formattedDate) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          'Date: $formattedDate',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRejectionRow(String reason) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        'Rejection Reason: $reason',
        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
      ),
    );
  }

  Widget _buildApprovalRow(String? approvedBy) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        'Approved by: ${approvedBy ?? 'Unknown'}',
        style: const TextStyle(color: Colors.green, fontSize: 14),
      ),
    );
  }
}
