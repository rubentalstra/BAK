import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/ui/home/chucked/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class ChuckedScreen extends StatefulWidget {
  const ChuckedScreen({super.key});

  @override
  _ChuckedScreenState createState() => _ChuckedScreenState();
}

class _ChuckedScreenState extends State<ChuckedScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
        title: const Text('Chucked Bak'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'transactions') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChuckedTransactionsScreen(),
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
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            return _buildRequestConsumedBakScreen(
                context, state.selectedAssociation.id);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildRequestConsumedBakScreen(
      BuildContext context, String associationId) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  try {
                    final amount = int.tryParse(_amountController.text);
                    if (amount != null && amount > 0) {
                      await requestConsumedBak(
                        associationId: associationId,
                        amount: amount,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Consumed Bak request sent!'),
                        backgroundColor: Colors.green,
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please enter a valid amount'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error requesting consumed bak: $e'),
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
                icon: const Icon(Icons.receipt_long),
                label: const Text('Request Chucked Bak'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
