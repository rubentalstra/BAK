import 'package:bak_tracker/core/const/drink_types.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/user/user_bloc.dart';
import 'package:bak_tracker/bloc/user/user_event.dart';
import 'package:bak_tracker/core/themes/colors.dart';

class LogDrinkScreen extends StatefulWidget {
  const LogDrinkScreen({super.key});

  @override
  LogDrinkScreenState createState() => LogDrinkScreenState();
}

class LogDrinkScreenState extends State<LogDrinkScreen> {
  DrinkType? selectedDrinkType;

  void _logDrink(BuildContext context, DrinkType drinkType) {
    context.read<UserBloc>().add(LogAlcoholConsumption(drinkType.name));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${drinkType.name} logged successfully!'),
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      selectedDrinkType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Drink'),
        backgroundColor: AppColors.lightPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Drink Type',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildDrinkSelection(),
              const SizedBox(height: 30),
              if (selectedDrinkType != null)
                Center(
                  child: _buildLogDrinkButton(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkSelection() {
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: DrinkType.values.map((drinkType) {
        final isSelected = selectedDrinkType == drinkType;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedDrinkType = drinkType;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.lightSecondary
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.lightPrimary : Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  drinkType.icon, // Use the icon from DrinkType extension
                  color: isSelected ? Colors.white : AppColors.lightSecondary,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  drinkType.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.lightSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogDrinkButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(FontAwesomeIcons.circleCheck),
      label: const Text(
        'Log Drink',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        backgroundColor: AppColors.lightPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onPressed: () {
        _logDrink(context, selectedDrinkType!);
      },
    );
  }
}
