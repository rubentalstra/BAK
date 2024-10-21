import 'package:bak_tracker/core/const/drink_types.dart';
import 'package:bak_tracker/ui/profile/drink_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/user/user_bloc.dart';
import 'package:bak_tracker/bloc/user/user_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';

class TotalConsumptionScreen extends StatelessWidget {
  final String userId;
  const TotalConsumptionScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Alcohol Consumption'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DrinkHistoryScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoaded) {
            final totalConsumption = state.totalConsumption;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: DrinkType.values.length,
              itemBuilder: (context, index) {
                final drinkType = DrinkType.values[index];
                final totalAmount = totalConsumption[drinkType] ?? 0;

                return _buildDrinkTypeCard(drinkType, totalAmount);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDrinkTypeCard(DrinkType drinkType, int totalAmount) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(drinkType.icon, color: AppColors.lightSecondary, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drinkType.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalAmount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
