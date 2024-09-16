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

  const LeaderboardWidget({super.key, required this.entries});

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
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                radius: 20.0,
                child: Text(
                  entry.rank.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.username,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(
                          'Consumed: ${entry.baksConsumed}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Text(
                          'Debt: ${entry.baksDebt}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              Icon(
                Icons.military_tech,
                color: Colors.amber[700],
                size: 28.0,
              ),
            ],
          ),
        );
      },
    );
  }
}
