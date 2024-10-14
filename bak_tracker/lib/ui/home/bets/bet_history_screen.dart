import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/core/utils/scroll_pagination_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BetHistoryScreen extends StatefulWidget {
  final String associationId;

  const BetHistoryScreen({super.key, required this.associationId});

  @override
  _BetHistoryScreenState createState() => _BetHistoryScreenState();
}

class _BetHistoryScreenState extends State<BetHistoryScreen> {
  final List<Map<String, dynamic>> _betHistory = [];
  final ScrollPaginationController _scrollPaginationController =
      ScrollPaginationController();

  @override
  void initState() {
    super.initState();
    _scrollPaginationController.initScrollListener(_loadMore);
    _fetchBetHistory();
  }

  @override
  void dispose() {
    _scrollPaginationController.dispose();
    super.dispose();
  }

  Future<void> _fetchBetHistory({bool isLoadMore = false}) async {
    if (_scrollPaginationController.isFetchingMore ||
        !_scrollPaginationController.hasMoreData) return;

    setState(() {
      if (isLoadMore) {
        _scrollPaginationController.setFetchingMore(true);
      } else {
        _scrollPaginationController.setLoading(true);
        _betHistory.clear();
        _scrollPaginationController.resetPagination();
      }
    });

    final supabase = Supabase.instance.client;

    try {
      final betHistoryResponse = await supabase
          .from('bets')
          .select(
              'id, amount, status, bet_creator_id (id, name), bet_receiver_id (id, name), bet_description, winner_id, created_at')
          .eq('association_id', widget.associationId)
          .eq('status', 'settled')
          .order('created_at', ascending: false)
          .range(
              _scrollPaginationController.offset,
              _scrollPaginationController.offset +
                  _scrollPaginationController.limit -
                  1);

      if (!mounted) return;

      setState(() {
        if (betHistoryResponse.isEmpty ||
            betHistoryResponse.length < _scrollPaginationController.limit) {
          _scrollPaginationController.setHasMoreData(false);
        }

        _betHistory.addAll(List<Map<String, dynamic>>.from(betHistoryResponse));
        _scrollPaginationController.setLoading(false);
        _scrollPaginationController.setFetchingMore(false);
        _scrollPaginationController.incrementOffset();
      });
    } catch (e) {
      print('Error fetching bet history: $e');
      setState(() {
        _scrollPaginationController.setLoading(false);
        _scrollPaginationController.setFetchingMore(false);
      });
    }
  }

  void _loadMore() async {
    await _fetchBetHistory(isLoadMore: true);
  }

  Future<void> _refreshBetHistory() async {
    _scrollPaginationController.resetPagination();
    await _fetchBetHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bet History'),
      ),
      body: RefreshIndicator(
        color: AppColors.lightSecondary,
        onRefresh: _refreshBetHistory,
        child: _scrollPaginationController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _betHistory.isEmpty
                ? const Center(child: Text('No settled bets found'))
                : _buildBetHistoryList(),
      ),
    );
  }

  Widget _buildBetHistoryList() {
    return ListView.builder(
      controller: _scrollPaginationController.scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _betHistory.length +
          (_scrollPaginationController.isFetchingMore ||
                  !_scrollPaginationController.hasMoreData
              ? 1
              : 0),
      itemBuilder: (context, index) {
        if (index == _betHistory.length) {
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

        return _buildBetHistoryTile(_betHistory[index]);
      },
    );
  }

  Widget _buildBetHistoryTile(Map<String, dynamic> bet) {
    final creatorName = bet['bet_creator_id']['name'];
    final receiverName = bet['bet_receiver_id']['name'];
    final winnerName = bet['winner_id'] == bet['bet_creator_id']['id']
        ? creatorName
        : receiverName;
    final createdAt = DateTime.parse(bet['created_at']).toLocal();
    final formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);
    final amount = bet['amount'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(creatorName, receiverName),
            const SizedBox(height: 8),
            _buildAmountAndWinnerRow(amount, winnerName),
            const SizedBox(height: 8),
            _buildDescription(bet['bet_description']),
            const SizedBox(height: 8),
            _buildDateRow(formattedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(String creatorName, String receiverName) {
    return Row(
      children: [
        Icon(Icons.people, color: AppColors.lightSecondary, size: 24),
        const SizedBox(width: 8),
        Text(
          '$creatorName vs $receiverName',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAmountAndWinnerRow(int amount, String winnerName) {
    final amountText = amount == 1 ? '1 bak' : '$amount bakken';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(FontAwesomeIcons.beerMugEmpty,
                color: AppColors.lightSecondary, size: 20),
            const SizedBox(width: 8),
            Text('Amount: $amountText',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        Text(
          'Winner: $winnerName',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Row(
      children: [
        Icon(Icons.description, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(String formattedDate) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text('Date: $formattedDate',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
