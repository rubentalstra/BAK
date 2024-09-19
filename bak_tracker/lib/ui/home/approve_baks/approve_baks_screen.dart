import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApproveBaksScreen extends StatefulWidget {
  const ApproveBaksScreen({super.key});

  @override
  _ApproveBaksScreenState createState() => _ApproveBaksScreenState();
}

class _ApproveBaksScreenState extends State<ApproveBaksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _requestedBaks = [];
  List<Map<String, dynamic>> _processedBaks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBaks();
  }

  // Fetch Baks from the database
  Future<void> _fetchBaks() async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    try {
      // Fetch requested baks (status = 'pending')
      final requestedResponse = await supabase
          .from('bak_consumed')
          .select('id, amount, created_at, taker_id (id, name)')
          .eq('status', 'pending');

      // Fetch approved/rejected baks (status = 'approved' OR 'rejected')
      final processedResponse = await supabase
          .from('bak_consumed')
          .select(
              'id, amount, status, approved_by (id, name), created_at, taker_id (id, name)')
          .neq('status', 'pending'); // Query for both approved and rejected

      setState(() {
        _requestedBaks = List<Map<String, dynamic>>.from(requestedResponse);
        _processedBaks = List<Map<String, dynamic>>.from(processedResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching baks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Approve or reject a Bak
// Approve or reject a Bak
  Future<void> _updateBakStatus(
      String bakId, String status, String takerId, int amount) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    try {
      // Update the bak status in the database
      await supabase
          .from('bak_consumed')
          .update({'status': status, 'approved_by': userId}).eq('id', bakId);

      // If approved, increase the consumed count
      if (status == 'approved') {
        final takerResponse = await supabase
            .from('association_members')
            .select('baks_consumed')
            .eq('user_id', takerId)
            .single();

        final updatedConsumed = takerResponse['baks_consumed'] + amount;

        await supabase
            .from('association_members')
            .update({'baks_consumed': updatedConsumed}).eq('user_id', takerId);
      }
      // If rejected, increase the bak debt count
      else if (status == 'rejected') {
        final takerResponse = await supabase
            .from('association_members')
            .select('baks_received')
            .eq('user_id', takerId)
            .single();

        final updatedReceived = takerResponse['baks_received'] + amount;

        await supabase
            .from('association_members')
            .update({'baks_received': updatedReceived}).eq('user_id', takerId);
      }

      // Refresh the list after approval/rejection
      _fetchBaks();
    } catch (e) {
      print('Error updating bak status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Baks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Requested'),
            Tab(text: 'Approved/Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestedTab(), // Tab for requested baks
                _buildProcessedTab(), // Tab for approved/rejected baks
              ],
            ),
    );
  }

  // Build the tab for requested Baks
  Widget _buildRequestedTab() {
    if (_requestedBaks.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    return ListView.builder(
      itemCount: _requestedBaks.length,
      itemBuilder: (context, index) {
        final bak = _requestedBaks[index];
        final takerName = bak['taker_id']['name']; // Fetch the taker name
        final takerId = bak['taker_id']['id']; // Fetch the taker ID
        final bakAmount = bak['amount']; // Fetch the bak amount

        return ListTile(
          title: Text('Bak Amount: ${bak['amount']}'),
          subtitle: Text('Requested by: $takerName'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () =>
                    _updateBakStatus(bak['id'], 'approved', takerId, bakAmount),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () =>
                    _updateBakStatus(bak['id'], 'rejected', takerId, bakAmount),
              ),
            ],
          ),
        );
      },
    );
  }

// Build the tab for approved/rejected Baks
  Widget _buildProcessedTab() {
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