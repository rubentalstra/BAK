import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  final int _limit = 10;
  int _offset = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchChuckedTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchChuckedTransactions({bool isMore = false}) async {
    if (_isFetchingMore || !_hasMoreData) return;

    if (isMore) {
      setState(() {
        _isFetchingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _processedBaks.clear();
        _offset = 0;
        _hasMoreData = true;
      });
    }

    final supabase = Supabase.instance.client;

    try {
      final processedResponse = await supabase
          .from('bak_consumed')
          .select(
              'id, amount, status, approved_by (id, name), created_at, taker_id (id, name)')
          .neq('status', 'pending')
          .eq('association_id', widget.associationId)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      if (!mounted) return;

      setState(() {
        if (processedResponse.isEmpty || processedResponse.length < _limit) {
          _hasMoreData = false;
        }

        _processedBaks
            .addAll(List<Map<String, dynamic>>.from(processedResponse));
        _isLoading = false;
        _isFetchingMore = false;
        _offset += _limit;
      });
    } catch (e) {
      print('Error fetching processed baks: $e');
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isFetchingMore &&
        _hasMoreData) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_hasMoreData) {
      await _fetchChuckedTransactions(isMore: true);
    }
  }

  Future<void> _refreshTransactions() async {
    await _fetchChuckedTransactions();
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _processedBaks.isEmpty
                ? const Center(child: Text('No approved or rejected baks'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _processedBaks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _processedBaks.length) {
                        if (_isFetchingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!_hasMoreData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: Text('No more data to load')),
                          );
                        }

                        return const SizedBox();
                      }

                      return _buildTransactionTile(_processedBaks[index]);
                    },
                  ),
      ),
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
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year}';

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
        const Icon(
          Icons.person,
          size: 20,
        ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
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
