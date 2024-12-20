import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/bak_consumed_model.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/association_settings/approve_baks/approve_bak_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    setState(() => _isLoading = true);
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
      });
    } catch (e) {
      _showSnackBar('Error fetching baks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBakStatus(BakConsumedModel bak, String status,
      {String? rejectionReason}) async {
    try {
      final supabase = Supabase.instance.client;
      final updateData = {
        'status': status,
        'approved_by': supabase.auth.currentUser?.id,
        if (rejectionReason != null) 'reason': rejectionReason,
      };

      await supabase.from('bak_consumed').update(updateData).eq('id', bak.id);

      if (status == 'approved') {
        await _adjustBaksOnApproval(
            bak.taker.id, bak.amount, bak.associationId);
        await _incrementBakStreak(bak.taker.id, bak.associationId);
      } else if (status == 'rejected') {
        await _adjustBaksOnRejection(
            bak.taker.id, bak.amount, bak.associationId);
      }

      await _fetchBaks();
      _sendNotification(bak.taker.id, status);
    } catch (e) {
      _showSnackBar('Error updating bak status: $e');
    }
  }

  Future<void> _adjustBaksOnApproval(
      String takerId, int amount, String associationId) async {
    await _adjustBakAmounts(takerId, associationId, amount, isApproval: true);
  }

  Future<void> _adjustBaksOnRejection(
      String takerId, int amount, String associationId) async {
    await _adjustBakAmounts(takerId, associationId, amount, isApproval: false);
  }

  Future<void> _adjustBakAmounts(
      String takerId, String associationId, int amount,
      {required bool isApproval}) async {
    final supabase = Supabase.instance.client;

    final memberResponse = await supabase
        .from('association_members')
        .select('baks_consumed, baks_received')
        .eq('user_id', takerId)
        .eq('association_id', associationId)
        .single();

    final int baksConsumed = memberResponse['baks_consumed'];
    final int baksReceived = memberResponse['baks_received'];

    final updatedConsumed = isApproval ? baksConsumed + amount : baksConsumed;
    final updatedReceived = isApproval
        ? (baksReceived - amount).clamp(0, baksReceived)
        : baksReceived + amount;

    await supabase
        .from('association_members')
        .update({
          'baks_consumed': updatedConsumed,
          'baks_received': updatedReceived,
        })
        .eq('user_id', takerId)
        .eq('association_id', associationId);
  }

  // Increment the bak streak on approval
  Future<void> _incrementBakStreak(String userId, String associationId) async {
    final supabase = Supabase.instance.client;

    // Fetch current streak and last bak activity
    final memberResponse = await supabase
        .from('association_members')
        .select('bak_streak')
        .eq('user_id', userId)
        .eq('association_id', associationId)
        .single();

    int currentStreak = memberResponse['bak_streak'] ?? 0;

    // Increment the streak
    currentStreak += 1;

    // Update the streak and last bak activity in the database
    await supabase
        .from('association_members')
        .update({
          'bak_streak': currentStreak,
          'last_bak_activity': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('association_id', associationId);
  }

  Future<void> _sendNotification(String userId, String status) async {
    final title =
        status == 'approved' ? 'Bak Request Approved' : 'Bak Request Rejected';
    final body = status == 'approved'
        ? 'Your bak request has been approved!'
        : 'Your bak request has been rejected.';

    await Supabase.instance.client.from('notifications').insert({
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
                child:
                    CircularProgressIndicator(color: AppColors.lightSecondary),
              )
            : _requestedBaks.isEmpty
                ? _buildEmptyState()
                : _buildBakList(),
      ),
    );
  }

  // Build the empty state widget
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          'Requested by: ${bak.taker.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildIconRow(
              FontAwesomeIcons.beerMugEmpty,
              'Bakken: ${bak.amount}',
            ),
            const SizedBox(height: 4),
            _buildIconRow(Icons.calendar_today,
                'Requested on: ${_formatDate(bak.createdAt)}'),
          ],
        ),
        trailing: _buildTrailingActions(bak),
      ),
    );
  }

  // Build icon and text row for the ListTile
  Widget _buildIconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // Build trailing approve/reject actions
  Widget _buildTrailingActions(BakConsumedModel bak) {
    return Row(
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
    );
  }
}
