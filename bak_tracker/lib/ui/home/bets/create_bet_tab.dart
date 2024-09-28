import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bak_tracker/services/bak_service.dart';
import 'package:bak_tracker/models/association_member_model.dart';

class CreateBetTab extends StatefulWidget {
  final String associationId;
  final List<AssociationMemberModel> members;

  const CreateBetTab({
    super.key,
    required this.associationId,
    required this.members,
  });

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
      _selectedReceiverId = widget.members.first.userId;
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8.0),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            Text(
              'Bet Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter bet description',
                    icon: Icon(Icons.message, color: Colors.blue),
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bet Amount (Bakken)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter amount',
                    icon: FaIcon(FontAwesomeIcons.beerMugEmpty,
                        color: AppColors.lightSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_selectedReceiverId != null) {
                    final amount = int.tryParse(_amountController.text) ?? 0;
                    final description = _descriptionController.text;
                    if (amount > 0 && description.isNotEmpty) {
                      try {
                        await BakService.createBet(
                          receiverId: _selectedReceiverId!,
                          associationId: widget.associationId,
                          amount: amount,
                          description: description,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Bet created successfully!'),
                              backgroundColor: Colors.green),
                        );

                        _amountController.clear();
                        _descriptionController.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating bet: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.send),
                label: const Text(
                  'Create Bet',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
