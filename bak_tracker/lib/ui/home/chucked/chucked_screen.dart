import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/ui/home/chucked/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bak_tracker/services/bak_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chucked Bak'),
          actions: [
            BlocBuilder<AssociationBloc, AssociationState>(
              builder: (context, state) {
                if (state is AssociationLoaded) {
                  return _buildHistoryIconButton(
                    context,
                    state.selectedAssociation.id,
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
        body: BlocBuilder<AssociationBloc, AssociationState>(
          builder: (context, state) {
            if (state is AssociationLoaded) {
              return _buildRequestConsumedBakScreen(
                  state.selectedAssociation.id);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _buildHistoryIconButton(BuildContext context, String associationId) {
    return IconButton(
      icon: const Icon(Icons.history),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChuckedTransactionsScreen(
              associationId: associationId,
            ),
          ),
        );
      },
      tooltip: 'Chucked History',
    );
  }

  Widget _buildRequestConsumedBakScreen(String associationId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Amount'),
          const SizedBox(height: 8.0),
          _buildAmountField(),
          const SizedBox(height: 24.0),
          _buildRequestButton(associationId),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildAmountField() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildRequestButton(String associationId) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: () => _handleRequestBak(associationId),
        icon: const Icon(FontAwesomeIcons.paperPlane),
        label: const Text(
          'Request Chucked Bak',
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRequestBak(String associationId) async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Error: Please enter a valid amount');
      return;
    }

    try {
      await BakService.requestConsumedBak(
        associationId: associationId,
        amount: amount,
      );
      _showSnackBar('Consumed Bak request sent!');
      _amountController.clear();
    } catch (e) {
      _showSnackBar('Error requesting consumed bak: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'OK',
          onPressed: ScaffoldMessenger.of(context).hideCurrentSnackBar,
        ),
      ),
    );
  }
}
