import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/widgets/profile_image_widget.dart';

class UpdateRolesScreen extends StatefulWidget {
  final String associationId;
  final ImageUploadService imageUploadService; // Add ImageUploadService

  const UpdateRolesScreen({
    super.key,
    required this.associationId,
    required this.imageUploadService, // Add parameter
  });

  @override
  _UpdateRolesScreenState createState() => _UpdateRolesScreenState();
}

class _UpdateRolesScreenState extends State<UpdateRolesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Roles'),
        backgroundColor: AppColors.lightPrimary,
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.lightSecondary),
            );
          } else if (state is AssociationLoaded) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: state.members.length,
                itemBuilder: (context, index) {
                  final member = state.members[index];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    color: AppColors.cardBackground,
                    child: ListTile(
                      leading: ProfileImageWidget(
                        profileImageUrl: member.user.profileImage,
                        userName: member.user.name,
                        fetchProfileImage: widget
                            .imageUploadService.fetchOrDownloadProfileImage,
                        radius: 24.0,
                      ),
                      title: Text(
                        member.user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightOnPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Current role: ${member.role}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppColors.lightSecondary),
                        onPressed: () async {
                          final newRole =
                              await _showRoleDialog(member.role ?? '');
                          if (newRole != null && newRole.isNotEmpty) {
                            context
                                .read<AssociationBloc>()
                                .add(UpdateMemberRole(
                                  associationId: widget.associationId,
                                  memberId: member.user.id,
                                  newRole: newRole,
                                ));
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const Center(child: Text('Error loading members.'));
          }
        },
      ),
    );
  }

  // Dialog to update the role with the current role pre-filled
  Future<String?> _showRoleDialog(String currentRole) {
    final roleController = TextEditingController(text: currentRole);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Enter New Role',
            style: TextStyle(color: AppColors.lightPrimary),
          ),
          content: TextField(
            controller: roleController,
            decoration: const InputDecoration(
              hintText: 'New role',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.lightSecondary),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.lightSecondary),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.lightSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () => Navigator.pop(context, roleController.text),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
