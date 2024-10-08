import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class BetHistoryScreen extends StatefulWidget {
  const BetHistoryScreen({super.key});

  @override
  _BetHistoryScreenState createState() => _BetHistoryScreenState();
}

class _BetHistoryScreenState extends State<BetHistoryScreen> {
  List<Map<String, dynamic>> _betHistory = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  String? _selectedAssociationId;

  final int _limit = 10;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchBetHistory(String associationId,
      {bool isLoadMore = false}) async {
    if (!isLoadMore) {
      _isLoading = true;
    } else {
      _isFetchingMore = true;
    }

    final supabase = Supabase.instance.client;

    try {
      final betHistoryResponse = await supabase
          .from('bets')
          .select(
              'id, amount, status, bet_creator_id (id, name), bet_receiver_id (id, name), bet_description, winner_id, created_at')
          .eq('status', 'settled')
          .eq('association_id', associationId)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      if (!mounted) return;

      setState(() {
        if (isLoadMore) {
          _betHistory
              .addAll(List<Map<String, dynamic>>.from(betHistoryResponse));
        } else {
          _betHistory = List<Map<String, dynamic>>.from(betHistoryResponse);
        }
        _isLoading = false;
        _isFetchingMore = false;
        _offset += _limit;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
      print('Error fetching bet history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bet History'),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            final associationId = state.selectedAssociation.id;
            if (_selectedAssociationId != associationId) {
              _selectedAssociationId = associationId;
              _offset = 0;
              _fetchBetHistory(associationId);
            }

            return RefreshIndicator(
              color: AppColors.lightSecondary,
              onRefresh: () {
                _offset = 0;
                return _fetchBetHistory(associationId);
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBetHistoryList(),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildBetHistoryList() {
    if (_betHistory.isEmpty) {
      return const Center(child: Text('No settled bets found'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isFetchingMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _fetchBetHistory(_selectedAssociationId!, isLoadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _betHistory.length + (_isFetchingMore ? 1 : 0),
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          if (index == _betHistory.length) {
            return _isFetchingMore
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          return _buildBetHistoryItem(_betHistory[index]);
        },
      ),
    );
  }

  Widget _buildBetHistoryItem(Map<String, dynamic> bet) {
    final creatorName = bet['bet_creator_id']['name'];
    final receiverName = bet['bet_receiver_id']['name'];
    final winnerName = bet['winner_id'] == bet['bet_creator_id']['id']
        ? creatorName
        : receiverName;
    final createdAt = DateTime.parse(bet['created_at']).toLocal();
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year}';
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
