import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/ui/home/bak/received_bak_screen.dart';
import 'package:bak_tracker/ui/home/bak/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class BakScreen extends StatefulWidget {
  const BakScreen({super.key});

  @override
  _BakScreenState createState() => _BakScreenState();
}

class _BakScreenState extends State<BakScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedReceiverId;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> sendBak({
    required String receiverId,
    required String associationId,
    required int amount,
    required String reason,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      // Fetch the giver's name from the users table
      final userResponse =
          await supabase.from('users').select('name').eq('id', userId).single();

      final giverName = userResponse['name']; // Fetch the correct display name

      // Insert Bak Send record into 'bak_send' table
      await supabase.from('bak_send').insert({
        'giver_id': userId,
        'receiver_id': receiverId,
        'association_id': associationId,
        'amount': amount,
        'reason': reason, // Insert reason
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notification to the receiver
      await _insertNotification(
        receiverId: receiverId,
        giverName: giverName, // Use the fetched name
        reason: reason,
      );

      _amountController.clear();
      _reasonController.clear(); // Clear reason field after sending
    } catch (e) {
      rethrow; // Handle error
    }
  }

// Helper function to insert notification into the notifications table
  Future<void> _insertNotification({
    required String receiverId,
    required String giverName, // Add giver's name
    required String reason,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      // Insert notification record
      await supabase.from('notifications').insert({
        'user_id': receiverId,
        'title':
            'You received a Bak from $giverName!', // Add giver's name to title
        'body': 'Reason: $reason', // Add reason to the body
      });

      print('Notification sent to $receiverId');
    } catch (e) {
      print('Error inserting notification: $e');
    }
  }

  Future<void> requestConsumedBak({
    required String associationId,
    required int amount,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('bak_consumed').insert({
        'taker_id': userId,
        'association_id': associationId,
        'amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Clear input field after successful request
      _amountController.clear();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bak'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'transactions') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'transactions',
                child: Text('Go to Transactions'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send Bak'),
            Tab(text: 'Received Bak'),
          ],
        ),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            final members = state.members; // Use cached members
            if (_selectedReceiverId == null && members.isNotEmpty) {
              _selectedReceiverId =
                  members.first.userId; // Select first member by default
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildSendBakTab(context, members),
                const ReceivedBakScreen(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // Tab 1: Send Bak
  Widget _buildSendBakTab(
      BuildContext context, List<AssociationMemberModel> members) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (members.isNotEmpty) ...[
              Text(
                'Select Receiver',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8.0),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.lightPrimary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: _selectedReceiverId,
                    hint: const Text('Choose a Receiver'),
                    onChanged: (value) {
                      setState(() {
                        _selectedReceiverId = value;
                      });
                    },
                    items: members.map((member) {
                      return DropdownMenuItem<String>(
                        value: member.userId,
                        child: Text(member.name!),
                      );
                    }).toList(),
                    isExpanded: true,
                    underline: Container(),
                    dropdownColor: AppColors.lightPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            Text(
              'Reason',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.lightPrimary,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller:
                      _reasonController, // Add a TextEditingController for reason
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Enter reason for sending the Bak',
                    labelStyle: TextStyle(
                      color: Colors.grey, // Default color when not focused
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.lightPrimary,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Enter amount',
                    labelStyle: TextStyle(
                      color: Colors.grey, // Default color when not focused
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: MediaQuery.of(context).size.width < 600
                  ? Alignment.center
                  : Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_selectedReceiverId == null ||
                      _reasonController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please select a receiver, enter an amount, and provide a reason.')),
                    );
                    return;
                  }
                  try {
                    await sendBak(
                      receiverId: _selectedReceiverId!,
                      associationId: members[0].associationId,
                      amount: int.parse(_amountController.text),
                      reason: _reasonController.text,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Bak sent successfully!'),
                      backgroundColor: Colors.green,
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sending bak: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 12.0),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Send Bak'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
