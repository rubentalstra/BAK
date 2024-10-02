import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProcessedBaksTransactionsScreen extends StatefulWidget {
  final String associationId; // Pass associationId to the screen

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
  bool _hasMoreData = true; // Track if there is more data to load
  final int _limit = 10; // Set limit for pagination
  int _offset = 0; // Track current offset

  @override
  void initState() {
    super.initState();
    _fetchChuckedTransactions(); // Initial fetch
  }

  Future<void> _fetchChuckedTransactions({bool isMore = false}) async {
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
          .eq('association_id',
              widget.associationId) // Use associationId from the widget
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
      await _fetchChuckedTransactions(isMore: true);
    }
  }

  Future<void> _refreshTransactions() async {
    await _fetchChuckedTransactions(); // Refresh with the current associationId
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chucked Transactions'),
      ),
      body: RefreshIndicator(
        color: AppColors.lightSecondary,
        onRefresh: _refreshTransactions, // Pull-to-refresh
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _processedBaks.isEmpty
                ? const Center(child: Text('No approved or rejected baks'))
                : ListView.builder(
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

                        return const SizedBox(); // Just a placeholder for spacing
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
                      final createdAt =
                          DateTime.parse(bak['created_at']).toLocal();
                      final formattedDate =
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Requested by
                            Row(
                              children: [
                                Text(
                                  'Requested by: $takerName',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
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
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
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
                                    ? Icon(Icons.gpp_bad,
                                        size: 16, color: Colors.grey)
                                    : Icon(Icons.verified_user,
                                        size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    status == 'REJECTED'
                                        ? 'Rejected by: $approvedBy'
                                        : 'Approved by: $approvedBy',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
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
