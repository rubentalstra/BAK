import 'package:bak_tracker/core/const/drink_types.dart';
import 'package:bak_tracker/models/alcohol_tracking_model.dart';
import 'package:bak_tracker/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrinkHistoryScreen extends StatefulWidget {
  final String userId;

  const DrinkHistoryScreen({super.key, required this.userId});

  @override
  DrinkHistoryScreenState createState() => DrinkHistoryScreenState();
}

class DrinkHistoryScreenState extends State<DrinkHistoryScreen> {
  late Future<List<AlcoholTrackingModel>> _drinkLogs;

  @override
  void initState() {
    super.initState();
    _drinkLogs = _fetchDrinkLogs();
  }

  Future<List<AlcoholTrackingModel>> _fetchDrinkLogs() async {
    final supabaseClient = Supabase.instance.client;
    final UserService userService = UserService(supabaseClient);
    return await userService.getAlcoholLogs(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drink Log History'),
      ),
      body: FutureBuilder<List<AlcoholTrackingModel>>(
        future: _drinkLogs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No drink logs available.'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final log = snapshot.data![index];
                return _buildDrinkLogCard(log);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDrinkLogCard(AlcoholTrackingModel log) {
    final drinkType = log.drinkType.name;
    final consumedAt = log.consumedAt.toLocal();

    final dateTimeFormatted = DateFormat.yMMMd().add_jm().format(consumedAt);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(log.drinkType.icon, color: Colors.orangeAccent),
        title: Text('$drinkType - ${log.amount} drink'),
        subtitle: Text('Consumed on: $dateTimeFormatted'),
      ),
    );
  }
}
