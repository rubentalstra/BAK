import 'package:flutter/material.dart';
import 'package:bak_tracker/models/association_achievement_model.dart';
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
  Future<List<AssociationAchievementModel>>? _achievementsFuture;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() {
    setState(() {
      _achievementsFuture =
          widget.associationService.fetchAchievements(widget.associationId);
    });
    return _achievementsFuture!;
  }

  Future<void> _createOrUpdateAchievement(
      {String? achievementId,
      required String name,
      String? description}) async {
    try {
      if (achievementId == null) {
        await widget.associationService.createAchievement(
          widget.associationId,
          name,
          description,
        );
      } else {
        await widget.associationService.updateAchievement(
          achievementId,
          name,
          description,
        );
      }
      await _loadAchievements();
    } catch (e) {
      _showErrorDialog('Error occurred: ${e.toString()}');
    }
  }

  Future<void> _deleteAchievement(String achievementId) async {
    try {
      await widget.associationService.deleteAchievement(achievementId);
      await _loadAchievements();
    } catch (e) {
      _showErrorDialog('Error deleting achievement: ${e.toString()}');
    }
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAchievementDialog(
      {String? achievementId,
      String? initialName,
      String? initialDescription}) async {
    final TextEditingController nameController =
        TextEditingController(text: initialName);
    final TextEditingController descriptionController =
        TextEditingController(text: initialDescription);

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(achievementId == null
              ? 'Create Achievement'
              : 'Edit Achievement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop();
                  _createOrUpdateAchievement(
                    achievementId: achievementId,
                    name: name,
                    description: description.isNotEmpty ? description : null,
                  );
                }
              },
              child: Text(achievementId == null ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAchievementDialog(),
        tooltip: 'Create Achievement',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<AssociationAchievementModel>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                        _showAchievementDialog(
                          achievementId: achievement.id,
                          initialName: achievement.name,
                          initialDescription: achievement.description,
                        );
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
}
