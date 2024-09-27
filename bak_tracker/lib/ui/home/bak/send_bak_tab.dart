import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/services/bak_service.dart'; // Service for sending bak

class SendBakTab extends StatefulWidget {
  final List<AssociationMemberModel> members;

  const SendBakTab({super.key, required this.members});

  @override
  _SendBakTabState createState() => _SendBakTabState();
}

class _SendBakTabState extends State<SendBakTab> {
  String? _selectedReceiverId;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.members.isNotEmpty) {
      _selectedReceiverId =
          widget.members.first.userId; // Default to first member
    }
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
            _buildReceiverDropdown(),
            const SizedBox(height: 16),
            _buildReasonField(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 24),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Receiver',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
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
                  child: Text(member.name ?? 'Unknown'),
                );
              }).toList(),
              isExpanded: true,
              underline: Container(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason',
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
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason for sending the Bak',
                icon: Icon(Icons.message, color: Colors.blue),
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount (Bakken)',
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
      ],
    );
  }

  Widget _buildSendButton() {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (_selectedReceiverId == null || _reasonController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Please select a receiver, enter an amount, and provide a reason.'),
              ),
            );
            return;
          }
          try {
            await BakService.sendBak(
              receiverId: _selectedReceiverId!,
              associationId: widget.members.first.associationId,
              amount: int.parse(_amountController.text),
              reason: _reasonController.text,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Bak sent successfully!'),
                  backgroundColor: Colors.green),
            );
            _amountController.clear();
            _reasonController.clear();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error sending Bak: $e'),
                  backgroundColor: Colors.red),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.send),
        label: const Text('Send Bak', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
