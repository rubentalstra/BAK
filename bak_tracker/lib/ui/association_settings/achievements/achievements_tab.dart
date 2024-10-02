import 'package:flutter/material.dart';
import 'package:bak_tracker/models/achievement_model.dart';
import 'package:intl/intl.dart';
import 'package:bak_tracker/services/association_service.dart';

class AchievementsTab extends StatefulWidget {
  final String associationId;
  final AssociationService associationService;

  const AchievementsTab({
    super.key,
    required this.associationId,
    required this.associationService,
  });

  @override
  _AchievementsTabState createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  Future<List<AchievementModel>>? _achievementsFuture;

  @override
  void initState() {
    super.initState();
    _achievementsFuture =
        widget.associationService.fetchAchievements(widget.associationId);
  }

  Future<void> _createAchievement(String name, String? description) async {
    await widget.associationService
        .createAchievement(widget.associationId, name, description);
    setState(() {
      _achievementsFuture =
          widget.associationService.fetchAchievements(widget.associationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAchievementDialog(),
        tooltip: 'Create Achievement',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<AchievementModel>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No achievements available.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final achievements = snapshot.data!;

          return ListView.builder(
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: const Icon(Icons.emoji_events,
                      color: Colors.orangeAccent),
                  title: Text(
                    achievement.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('HH:mm dd-MM-yyyy')
                        .format(achievement.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String result) {
                      if (result == 'Edit') {
                        _showEditAchievementDialog(achievement);
                      } else if (result == 'Delete') {
                        _deleteAchievement(achievement.id);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Achievement'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete Achievement'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateAchievementDialog() async {
    String name = '';
    String? description;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Achievement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () {
                if (name.isNotEmpty) {
                  _createAchievement(name, description);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditAchievementDialog(AchievementModel achievement) async {
    String name = achievement.name;
    String? description = achievement.description;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Achievement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
                controller: TextEditingController(text: name),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
                controller: TextEditingController(text: description),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (name.isNotEmpty) {
                  await widget.associationService
                      .updateAchievement(achievement.id, name, description);
                  Navigator.of(context).pop();
                  setState(() {
                    _achievementsFuture = widget.associationService
                        .fetchAchievements(widget.associationId);
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAchievement(String achievementId) async {
    await widget.associationService.deleteAchievement(achievementId);
    setState(() {
      _achievementsFuture =
          widget.associationService.fetchAchievements(widget.associationId);
    });
  }
}
