import 'package:flutter/material.dart';

class LeaderboardEntry {
  final int rank;
  final String username;
  final int baksConsumed;
  final int baksDebt;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.baksConsumed,
    required this.baksDebt,
  });
}

class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const LeaderboardWidget({Key? key, required this.entries}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => Divider(
        height: 1.0,
        color: Colors.grey[300],
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          color: Colors.white,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              child: Text(entry.rank.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(
              entry.username,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baks Consumed: ${entry.baksConsumed}',
                  style: TextStyle(color: Colors.green[700]),
                ),
                Text(
                  'Baks Debt: ${entry.baksDebt}',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
            trailing: Icon(
              Icons.star,
              color: Colors.amber,
              size: 24.0,
            ),
          ),
        );
      },
    );
  }
}
