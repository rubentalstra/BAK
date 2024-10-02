import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/models/achievement_model.dart';

class MembersTab extends StatefulWidget {
  final String associationId;
  final ImageUploadService imageUploadService;
  final AssociationService associationService;

  const MembersTab({
    super.key,
    required this.associationId,
    required this.imageUploadService,
    required this.associationService,
  });

  @override
  _MembersTabState createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  Future<List<AssociationMemberModel>>? _membersFuture;
  Future<List<AchievementModel>>? _achievementsFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture =
        widget.associationService.fetchMembers(widget.associationId);
    _achievementsFuture =
        widget.associationService.fetchAchievements(widget.associationId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssociationMemberModel>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No members found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final members = snapshot.data!;

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return FutureBuilder<File?>(
              future: member.user.profileImage != null &&
                      member.user.profileImage!.isNotEmpty
                  ? widget.imageUploadService
                      .fetchOrDownloadProfileImage(member.user.profileImage!)
                  : Future.value(null),
              builder: (context, snapshot) {
                final imageFile = snapshot.data;

                return Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: _buildProfileImage(imageFile, member.user.name),
                    title: Text(
                      member.user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      member.role ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.emoji_events),
                      onPressed: () {
                        _showAssignAchievementDialog(member);
                      },
                    ),
                    onTap: () {
                      _showAssignAchievementDialog(member);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfileImage(File? imageFile, String userName) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: imageFile == null ? Colors.grey : null,
      backgroundImage: imageFile != null ? FileImage(imageFile) : null,
      child: imageFile == null
          ? Text(
              userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            )
          : null,
    );
  }

  // Show dialog to assign/remove achievements for a member
  Future<void> _showAssignAchievementDialog(
      AssociationMemberModel member) async {
    // Fetch the currently assigned achievements
    List<String> assignedAchievementIds = [];

    try {
      final response =
          await widget.associationService.fetchMemberAchievements(member.id);

      // Populate assignedAchievementIds with the actual achievement ids
      assignedAchievementIds =
          response.map((achievement) => achievement.achievement.id).toList();
    } catch (e) {
      print('Error fetching member achievements: $e');
    }

    // Show the dialog with achievements
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return FutureBuilder<List<AchievementModel>>(
              future: _achievementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No achievements available.'));
                }

                final achievements = snapshot.data!;

                return AlertDialog(
                  title: Text('Manage Achievements for ${member.user.name}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: achievements.map((achievement) {
                      return CheckboxListTile(
                        title: Text(achievement.name),
                        value: assignedAchievementIds.contains(achievement.id),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              assignedAchievementIds.add(achievement.id);
                            } else {
                              assignedAchievementIds.remove(achievement.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Save Changes'),
                      onPressed: () async {
                        await _updateAchievementsForMember(
                            member, assignedAchievementIds);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Update achievements for a member
  Future<void> _updateAchievementsForMember(AssociationMemberModel member,
      List<String> selectedAchievementIds) async {
    try {
      await widget.associationService.updateMemberAchievements(
        member.id,
        selectedAchievementIds,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievements updated successfully!')),
      );
    } catch (e) {
      print('Error updating achievements: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating achievements')),
      );
    }
  }
}
