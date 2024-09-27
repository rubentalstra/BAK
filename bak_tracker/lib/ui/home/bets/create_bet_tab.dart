import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_member_model.dart';

class CreateBetTab extends StatefulWidget {
  final String associationId;
  final List<AssociationMemberModel> members;

  const CreateBetTab({
    Key? key,
    required this.associationId,
    required this.members,
  }) : super(key: key);

  @override
  _CreateBetTabState createState() => _CreateBetTabState();
}

class _CreateBetTabState extends State<CreateBetTab> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedReceiverId;

  @override
  void initState() {
    super.initState();
    if (widget.members.isNotEmpty) {
      _selectedReceiverId = widget.members.first.userId; // Default first member
    }
  }

  Future<void> _createBet(
      String receiverId, int amount, String description) async {
    final supabase = Supabase.instance.client;
    final creatorId = supabase.auth.currentUser!.id;
    try {
      await supabase.from('bets').insert({
        'bet_creator_id': creatorId,
        'bet_receiver_id': receiverId,
        'association_id': widget.associationId,
        'amount': amount,
        'bet_description': description,
        'status': 'pending',
      });

      // Clear the input fields
      _descriptionController.clear();
      _amountController.clear();

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bet created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating bet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.members.isNotEmpty) ...[
              Text(
                'Select Bet Receiver',
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
                    items: widget.members.map((member) {
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
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Bet Description'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (Bakken)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_selectedReceiverId != null) {
                  final amount = int.tryParse(_amountController.text) ?? 0;
                  final description = _descriptionController.text;
                  if (amount > 0 && description.isNotEmpty) {
                    _createBet(_selectedReceiverId!, amount, description);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please enter a valid bet amount and description.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a receiver for the bet.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create Bet'),
            ),
          ],
        ),
      ),
    );
  }
}
