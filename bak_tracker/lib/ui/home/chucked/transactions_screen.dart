import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/models/bak_consumed_model.dart'; // Import your model
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/core/themes/colors.dart'; // Import your theme colors

class ChuckedTransactionsScreen extends StatefulWidget {
  const ChuckedTransactionsScreen({super.key});

  @override
  _ChuckedTransactionsScreenState createState() =>
      _ChuckedTransactionsScreenState();
}

class _ChuckedTransactionsScreenState extends State<ChuckedTransactionsScreen> {
  List<BakConsumedModel> _chuckedBakken = []; // Use BakConsumedModel here
  bool _isLoading = true;
  String? _selectedAssociationId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchChuckedTransactions(String associationId) async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    try {
      final chuckedResponse = await supabase
          .from('bak_consumed')
          .select(
              'id, amount, status, created_at, association_id, reason, approved_by (id, name), taker_id (id, name)')
          .eq('taker_id', currentUserId)
          .eq('association_id', associationId)
          .order('created_at', ascending: false);

      // Parse the response using BakConsumedModel
      final List<BakConsumedModel> chuckedBakkenList = chuckedResponse
          .map<BakConsumedModel>((data) => BakConsumedModel.fromMap(data))
          .toList();

      setState(() {
        _chuckedBakken = chuckedBakkenList;
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

  // Build the list of chucked transactions using BakConsumedModel
  Widget _buildTransactionsList() {
    if (_chuckedBakken.isEmpty) {
      return const Center(
        child: Text(
          'No transactions found.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _chuckedBakken.length,
      itemBuilder: (context, index) {
        final bak = _chuckedBakken[index];
        final date = bak.createdAt;
        final isRejected = bak.status == 'rejected';
        final rejectionReason = bak.reason ?? 'No reason provided';
        final approvedBy = bak.approvedBy?.name; // Admin who approved the bak

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.lightPrimary,
                      radius: 24,
                      child: Icon(
                        FontAwesomeIcons.beerMugEmpty,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Amount: ${bak.amount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Text(
                      bak.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(bak.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Date: ${DateFormat.yMMMd('nl_NL').format(date)} at ${DateFormat.Hm('nl_NL').format(date)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (isRejected)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Rejection Reason: $rejectionReason',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (bak.status == 'approved')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Approved by: ${approvedBy ?? 'Unknown'}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Extracted method for status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
