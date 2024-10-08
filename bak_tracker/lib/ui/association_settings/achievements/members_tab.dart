import 'dart:io';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/models/achievement_model.dart';
import 'package:bak_tracker/services/association_service.dart';

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
  late Future<List<AchievementModel>> _achievementsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch all available achievements for the association
    _achievementsFuture =
        widget.associationService.fetchAchievements(widget.associationId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssociationBloc, AssociationState>(
      builder: (context, state) {
        if (state is AssociationLoading) {
          return const Center(
              child: CircularProgressIndicator(
            color: AppColors.lightSecondary,
          ));
        } else if (state is AssociationLoaded) {
          final members = state.members;

          if (members.isEmpty) {
            return const Center(child: Text('No members found.'));
          }

          return RefreshIndicator(
            onRefresh: () => _onRefresh(context), // Handle pull-to-refresh
            color: AppColors.lightSecondary,
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return _buildMemberTile(context, member);
              },
            ),
          );
        } else {
          return const Center(child: Text('Error loading members.'));
        }
      },
    );
  }

  // Handle pull-to-refresh logic
  Future<void> _onRefresh(BuildContext context) async {
    // Re-fetch the members and achievements by triggering the appropriate Bloc event
    context.read<AssociationBloc>().add(SelectAssociation(
          selectedAssociation:
              (context.read<AssociationBloc>().state as AssociationLoaded)
                  .selectedAssociation,
        ));
  }

  // Build the list tile for each member
  Widget _buildMemberTile(BuildContext context, AssociationMemberModel member) {
    return FutureBuilder<File?>(
      future: _fetchProfileImage(member),
      builder: (context, snapshot) {
        final imageFile = snapshot.data;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            subtitle: Text(member.role ?? '',
                style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.emoji_events),
              onPressed: () => _showAssignAchievementDialog(context, member),
            ),
            onTap: () => _showAssignAchievementDialog(context, member),
          ),
        );
      },
    );
  }

  // Fetch the profile image lazily
  Future<File?> _fetchProfileImage(AssociationMemberModel member) {
    if (member.user.profileImage != null &&
        member.user.profileImage!.isNotEmpty) {
      return widget.imageUploadService
          .fetchOrDownloadProfileImage(member.user.profileImage!);
    }
    return Future.value(null);
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
    BuildContext context,
    AssociationMemberModel member,
  ) async {
    // Fetch the currently available achievements (already fetched in initState)
    List<String> assignedAchievementIds = member.achievements
        .map((achievement) => achievement.achievement.id)
        .toList(); // Assuming member has a list of assigned achievements

    showDialog<void>(
      context: context,
      builder: (context) =>
          _buildAchievementDialog(context, member, assignedAchievementIds),
    );
  }

  Widget _buildAchievementDialog(
    BuildContext context,
    AssociationMemberModel member,
    List<String> assignedAchievementIds,
  ) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return FutureBuilder<List<AchievementModel>>(
          future: _achievementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No achievements available.'));
            }

            final achievements = snapshot.data!;
            return AlertDialog(
              title: Text('Manage Achievements for ${member.user.name}'),
              content: _buildAchievementList(
                  achievements, assignedAchievementIds, setDialogState),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save Changes'),
                  onPressed: () => _saveAchievementChanges(
                      context, member, assignedAchievementIds),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementList(
    List<AchievementModel> achievements,
    List<String> assignedAchievementIds,
    StateSetter setDialogState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: achievements.map((achievement) {
        return CheckboxListTile(
          title: Text(achievement.name),
          value: assignedAchievementIds.contains(achievement
              .id), // Pre-select if the achievement is already assigned
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
    );
  }

// Update achievements for a member and refresh state
  Future<void> _saveAchievementChanges(
    BuildContext context,
    AssociationMemberModel member,
    List<String> selectedAchievementIds,
  ) async {
    try {
      await widget.associationService.updateMemberAchievements(
        member.id,
        selectedAchievementIds,
      );

      // Trigger a state update in the Bloc to refresh achievements
      context.read<AssociationBloc>().add(RefreshMemberAchievements(member.id));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievements updated successfully!')),
      );
    } catch (e) {
      print('Error updating achievements: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating achievements')),
      );
    }
    Navigator.of(context).pop();
  }
}
