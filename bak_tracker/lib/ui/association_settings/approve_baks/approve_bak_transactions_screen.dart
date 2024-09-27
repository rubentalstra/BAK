import 'package:bak_tracker/bloc/association/association_state.dart';
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
  List<Map<String, dynamic>> _processedBaks = [];
  bool _isLoading = true;
  String? _selectedAssociationId;

  @override
  void initState() {
    super.initState();
    // Initial fetching is deferred until the association is loaded
  }

  Future<void> _fetchChuckedTransactions(String associationId) async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    try {
      // Fetch approved/rejected baks for the current association
      final processedResponse = await supabase
          .from('bak_consumed')
          .select(
              'id, amount, status, approved_by (id, name), created_at, taker_id (id, name)')
          .neq('status', 'pending')
          .eq('association_id', associationId); // Use associationId filter

      if (!mounted) return; // Ensure the widget is still mounted
      setState(() {
        _processedBaks = List<Map<String, dynamic>>.from(processedResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching chucked transactions: $e');
      setState(() {
        _isLoading = false;
      });
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

// Build the list of chucked transactions
  Widget _buildTransactionsList() {
    if (_processedBaks.isEmpty) {
      return const Center(child: Text('No approved or rejected baks'));
    }

    return ListView.builder(
      itemCount: _processedBaks.length,
      itemBuilder: (context, index) {
        final bak = _processedBaks[index];
        final takerName = bak['taker_id']['name']; // Fetch the requester's name
        final approvedBy = bak['approved_by'] != null
            ? bak['approved_by']['name']
            : 'N/A'; // Approved by user or 'N/A'
        final status = bak['status'].toUpperCase();
        final statusColor = status == 'APPROVED' ? Colors.green : Colors.red;
        final createdAt = DateTime.parse(bak['created_at']).toLocal();
        final formattedDate =
            '${createdAt.day}/${createdAt.month}/${createdAt.year}';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Requested by
              Row(
                children: [
                  Text(
                    'Requested by: $takerName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              Row(
                children: [
                  const Icon(Icons.verified_user, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Approved by: $approvedBy',
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
    );
  }
}
