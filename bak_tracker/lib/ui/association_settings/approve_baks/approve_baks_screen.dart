import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/bak_consumed_model.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/association_settings/approve_baks/approve_bak_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApproveBaksScreen extends StatefulWidget {
  final String associationId;
  final ImageUploadService imageUploadService;

  const ApproveBaksScreen({
    super.key,
    required this.associationId,
    required this.imageUploadService,
  });

  @override
  _ApproveBaksScreenState createState() => _ApproveBaksScreenState();
}

class _ApproveBaksScreenState extends State<ApproveBaksScreen> {
  List<BakConsumedModel> _requestedBaks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBaks();
  }

  Future<void> _fetchBaks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requestedResponse = await Supabase.instance.client
          .from('bak_consumed')
          .select(
              'id, amount, created_at, taker_id (id, name), association_id, status, created_at')
          .eq('status', 'pending')
          .eq('association_id', widget.associationId);

      setState(() {
        _requestedBaks = (requestedResponse as List)
            .map((bakData) => BakConsumedModel.fromMap(bakData))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Error fetching baks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBakStatus(BakConsumedModel bak, String status,
      {String? rejectionReason}) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    try {
      final updateData = {
        'status': status,
        'approved_by': userId,
        if (rejectionReason != null) 'reason': rejectionReason,
      };

      await supabase.from('bak_consumed').update(updateData).eq('id', bak.id);

      if (status == 'approved') {
        await _adjustBaksOnApproval(
            bak.taker.id, bak.amount, bak.associationId);
      } else if (status == 'rejected') {
        await _adjustBaksOnRejection(
            bak.taker.id, bak.amount, bak.associationId);
      }

      _fetchBaks();
      _sendNotification(bak.taker.id, status);
    } catch (e) {
      _showSnackBar('Error updating bak status: $e');
    }
  }

  Future<void> _adjustBaksOnApproval(
      String takerId, int amount, String associationId) async {
    final supabase = Supabase.instance.client;

    final memberResponse = await supabase
        .from('association_members')
        .select('baks_consumed, baks_received')
        .eq('user_id', takerId)
        .eq('association_id', associationId)
        .single();

    final int currentBaksConsumed = memberResponse['baks_consumed'];
    final int currentBaksReceived = memberResponse['baks_received'];

    final updatedConsumed = currentBaksConsumed + amount;
    final updatedReceived =
        currentBaksReceived - amount < 0 ? 0 : currentBaksReceived - amount;

    await supabase
        .from('association_members')
        .update({
          'baks_consumed': updatedConsumed,
          'baks_received': updatedReceived,
        })
        .eq('user_id', takerId)
        .eq('association_id', associationId);
  }

  Future<void> _adjustBaksOnRejection(
      String takerId, int amount, String associationId) async {
    final supabase = Supabase.instance.client;

    final memberResponse = await supabase
        .from('association_members')
        .select('baks_received')
        .eq('user_id', takerId)
        .eq('association_id', associationId)
        .single();

    final int currentBaksReceived = memberResponse['baks_received'];
    final updatedReceived = currentBaksReceived + amount;

    await supabase
        .from('association_members')
        .update({
          'baks_received': updatedReceived,
        })
        .eq('user_id', takerId)
        .eq('association_id', associationId);
  }

  Future<void> _sendNotification(String userId, String status) async {
    final supabase = Supabase.instance.client;
    final title =
        status == 'approved' ? 'Bak Request Approved' : 'Bak Request Rejected';
    final body = status == 'approved'
        ? 'Your bak request has been approved!'
        : 'Your bak request has been rejected.';

    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
    });
  }

  Future<void> _showRejectDialog(BakConsumedModel bak) async {
    final reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Bak'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Rejection Reason'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  _updateBakStatus(bak, 'rejected',
                      rejectionReason: reasonController.text);
                  Navigator.of(context).pop();
                } else {
                  _showSnackBar('Please provide a rejection reason.');
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    return DateFormat('HH:mm dd-MM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Baks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProcessedBaksTransactionsScreen(
                      associationId: widget.associationId)),
            ),
            tooltip: 'Transactions',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.lightSecondary,
        onRefresh: _fetchBaks,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.lightSecondary,
                ),
              )
            : _requestedBaks.isEmpty
                ? _buildEmptyState()
                : _buildBakList(),
      ),
    );
  }

  // Build the empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No pending bak requests',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Build the list of pending bak requests
  Widget _buildBakList() {
    return ListView.builder(
      itemCount: _requestedBaks.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final bak = _requestedBaks[index];
        return _buildBakCard(bak);
      },
    );
  }

  // Build a single bak card
  Widget _buildBakCard(BakConsumedModel bak) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          'Bak Amount: ${bak.amount}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Requested by: ${bak.taker.name}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Requested on: ${_formatDate(bak.createdAt)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _updateBakStatus(bak, 'approved'),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _showRejectDialog(bak),
            ),
          ],
        ),
      ),
    );
  }
}
