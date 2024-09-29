import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class ProcessedBaksTransactionsScreen extends StatefulWidget {
  const ProcessedBaksTransactionsScreen({super.key});

  @override
  _ProcessedBaksTransactionsScreenState createState() =>
      _ProcessedBaksTransactionsScreenState();
}

class _ProcessedBaksTransactionsScreenState
    extends State<ProcessedBaksTransactionsScreen> {
  final List<Map<String, dynamic>> _processedBaks = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true; // Track if there is more data to load
  String? _selectedAssociationId;
  final int _limit = 10; // Set limit for pagination
  int _offset = 0; // Track current offset

  @override
  void initState() {
    super.initState();
    // Initial fetching is deferred until the association is loaded
  }

  Future<void> _fetchChuckedTransactions(String associationId,
      {bool isMore = false}) async {
    if (isMore) {
      setState(() {
        _isFetchingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _processedBaks.clear(); // Reset the data when fetching fresh
        _offset = 0; // Reset the offset when association changes
        _hasMoreData = true; // Reset the flag when association changes
      });
    }

    final supabase = Supabase.instance.client;

    try {
      // Fetch approved/rejected baks for the current association with pagination and sorting
      final processedResponse = await supabase
          .from('bak_consumed')
          .select(
              'id, amount, status, approved_by (id, name), created_at, taker_id (id, name)')
          .neq('status', 'pending')
          .eq('association_id', associationId) // Use associationId filter
          .order('created_at', ascending: false) // Sort by created_at desc
          .range(_offset, _offset + _limit - 1); // Pagination: use range

      if (!mounted) return; // Ensure the widget is still mounted

      // Check if there is no more data to fetch
      if (processedResponse.isEmpty || processedResponse.length < _limit) {
        _hasMoreData = false; // No more data to load
      }

      setState(() {
        _processedBaks
            .addAll(List<Map<String, dynamic>>.from(processedResponse));
        _isLoading = false;
        _isFetchingMore = false;
        _offset += _limit; // Update offset for next page
      });
    } catch (e) {
      print('Error fetching chucked transactions: $e');
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_hasMoreData) {
      await _fetchChuckedTransactions(_selectedAssociationId!, isMore: true);
    }
  }

  Future<void> _refreshTransactions() async {
    if (_selectedAssociationId != null) {
      await _fetchChuckedTransactions(_selectedAssociationId!);
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

  // Build the list of chucked transactions with paging and pull-to-refresh
  Widget _buildTransactionsList() {
    if (_processedBaks.isEmpty) {
      return const Center(child: Text('No approved or rejected baks'));
    }

    return RefreshIndicator(
      onRefresh: _refreshTransactions, // Pull-to-refresh
      color: AppColors.lightSecondary,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification.metrics.pixels ==
                  scrollNotification.metrics.maxScrollExtent &&
              !_isFetchingMore &&
              _hasMoreData) {
            _loadMore(); // Load more when scrolled to the bottom
          }
          return false;
        },
        child: ListView.builder(
          itemCount: _processedBaks.length +
              1, // +1 for loading indicator or no more data message
          itemBuilder: (context, index) {
            if (index == _processedBaks.length) {
              // Show a loading indicator at the bottom when fetching more
              if (_isFetchingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Show a message when no more data is available
              if (!_hasMoreData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: Text('No more data to load')),
                );
              }

              return const SizedBox();
            }

            final bak = _processedBaks[index];
            final takerName =
                bak['taker_id']['name']; // Fetch the requester's name
            final approvedBy = bak['approved_by'] != null
                ? bak['approved_by']['name']
                : 'N/A'; // Approved by user or 'N/A'
            final status = bak['status'].toString().toUpperCase();
            final statusColor =
                status == 'APPROVED' ? Colors.green : Colors.red;
            final createdAt = DateTime.parse(bak['created_at']).toLocal();
            final formattedDate =
                '${createdAt.day}/${createdAt.month}/${createdAt.year}';

            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Requested by
                  Row(
                    children: [
                      Text(
                        'Requested by: $takerName',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Amount and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_drink,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Bak: ${bak['amount']}',
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
                  ),
                  const SizedBox(height: 4),

                  // Approved or Rejected by
                  Row(
                    children: [
                      status == 'REJECTED'
                          ? Icon(Icons.gpp_bad, size: 16, color: Colors.grey)
                          : Icon(Icons.verified_user,
                              size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          // Change text based on the status
                          status == 'REJECTED'
                              ? 'Rejected by: $approvedBy'
                              : 'Approved by: $approvedBy',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date information
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Date: $formattedDate',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
