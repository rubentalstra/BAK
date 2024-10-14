import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/core/utils/scroll_pagination_controller.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProcessedBaksTransactionsScreen extends StatefulWidget {
  final String associationId;

  const ProcessedBaksTransactionsScreen(
      {super.key, required this.associationId});

  @override
  _ProcessedBaksTransactionsScreenState createState() =>
      _ProcessedBaksTransactionsScreenState();
}

class _ProcessedBaksTransactionsScreenState
    extends State<ProcessedBaksTransactionsScreen> {
  final List<Map<String, dynamic>> _processedBaks = [];
  final ScrollPaginationController _scrollPaginationController =
      ScrollPaginationController();

  @override
  void initState() {
    super.initState();
    _scrollPaginationController.initScrollListener(_loadMore);
    _fetchProcessedTransactions();
  }

  @override
  void dispose() {
    _scrollPaginationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProcessedTransactions({bool isLoadMore = false}) async {
    if (_scrollPaginationController.isFetchingMore ||
        !_scrollPaginationController.hasMoreData) return;

    setState(() {
      if (isLoadMore) {
        _scrollPaginationController.setFetchingMore(true);
      } else {
        _scrollPaginationController.setLoading(true);
        _processedBaks.clear();
        _scrollPaginationController.resetPagination();
      }
    });

    final supabase = Supabase.instance.client;

    try {
      final processedResponse = await supabase
          .from('bak_consumed')
          .select(
              'id, amount, status, approved_by (id, name), created_at, taker_id (id, name)')
          .neq('status', 'pending')
          .eq('association_id', widget.associationId)
          .order('created_at', ascending: false)
          .range(
              _scrollPaginationController.offset,
              _scrollPaginationController.offset +
                  _scrollPaginationController.limit -
                  1);

      if (!mounted) return;

      setState(() {
        if (processedResponse.isEmpty ||
            processedResponse.length < _scrollPaginationController.limit) {
          _scrollPaginationController.setHasMoreData(false);
        }

        _processedBaks
            .addAll(List<Map<String, dynamic>>.from(processedResponse));
        _scrollPaginationController.setLoading(false);
        _scrollPaginationController.setFetchingMore(false);
        _scrollPaginationController.incrementOffset();
      });
    } catch (e) {
      print('Error fetching processed baks: $e');
      setState(() {
        _scrollPaginationController.setLoading(false);
        _scrollPaginationController.setFetchingMore(false);
      });
    }
  }

  void _loadMore() async {
    await _fetchProcessedTransactions(isLoadMore: true);
  }

  Future<void> _refreshTransactions() async {
    await _fetchProcessedTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processed Bak Transactions'),
      ),
      body: RefreshIndicator(
        color: AppColors.lightSecondary,
        onRefresh: _refreshTransactions,
        child: _scrollPaginationController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _processedBaks.isEmpty
                ? const Center(child: Text('No approved or rejected baks'))
                : _buildTransactionsList(),
      ),
    );
  }

  // Method to build the list of transactions
  Widget _buildTransactionsList() {
    return ListView.builder(
      controller: _scrollPaginationController.scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _processedBaks.length + 1,
      itemBuilder: (context, index) {
        if (index == _processedBaks.length) {
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

          return const SizedBox();
        }

        return _buildTransactionTile(_processedBaks[index]);
      },
    );
  }

  // Extracted method to build individual transaction tiles
  Widget _buildTransactionTile(Map<String, dynamic> bak) {
    final takerName = bak['taker_id']['name'];
    final approvedBy =
        bak['approved_by'] != null ? bak['approved_by']['name'] : 'N/A';
    final status = bak['status'].toString().toUpperCase();
    final statusColor = status == 'APPROVED' ? Colors.green : Colors.red;
    final createdAt = DateTime.parse(bak['created_at']).toLocal();
    final formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransactionHeader(takerName),
            const SizedBox(height: 8),
            _buildAmountAndStatus(bak['amount'], status, statusColor),
            const SizedBox(height: 4),
            _buildApprovedOrRejected(status, approvedBy),
            const SizedBox(height: 4),
            _buildTransactionDate(formattedDate),
          ],
        ),
      ),
    );
  }

  // Extracted method for transaction header
  Widget _buildTransactionHeader(String takerName) {
    return Row(
      children: [
        const Icon(Icons.person, size: 20),
        const SizedBox(width: 8),
        Text(
          'Requested by: $takerName',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // Extracted method to display amount and status
  Widget _buildAmountAndStatus(int amount, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(FontAwesomeIcons.beerMugEmpty,
                size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Bakken: $amount',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        Text(
          status,
          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
        ),
      ],
    );
  }

  // Extracted method to show who approved or rejected the bak
  Widget _buildApprovedOrRejected(String status, String approvedBy) {
    return Row(
      children: [
        Icon(
          status == 'REJECTED' ? Icons.gpp_bad : Icons.verified_user,
          size: 20,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status == 'REJECTED'
                ? 'Rejected by: $approvedBy'
                : 'Approved by: $approvedBy',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  // Extracted method for transaction date
  Widget _buildTransactionDate(String formattedDate) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          'Date: $formattedDate',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
