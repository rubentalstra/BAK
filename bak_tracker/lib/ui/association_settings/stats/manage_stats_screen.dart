import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/widgets/profile_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';

class ManageStatsScreen extends StatefulWidget {
  final String associationId;
  final ImageUploadService imageUploadService;

  const ManageStatsScreen({
    super.key,
    required this.associationId,
    required this.imageUploadService,
  });

  @override
  _ManageStatsScreenState createState() => _ManageStatsScreenState();
}

class _ManageStatsScreenState extends State<ManageStatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Member Stats'),
        backgroundColor: AppColors.lightPrimary,
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AssociationLoaded) {
            final members = state.members;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: ProfileImageWidget(
                        profileImageUrl: member.user.profileImage,
                        userName: member.user.name,
                        fetchProfileImage: widget
                            .imageUploadService.fetchOrDownloadProfileImage,
                        radius: 24.0,
                      ),
                      title: Text(member.user.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow('Baks Received:',
                              '${member.baksReceived}', Colors.red),
                          _buildStatRow('Baks Consumed:',
                              '${member.baksConsumed}', Colors.green),
                          _buildStatRow(
                              'Bets Won:', '${member.betsWon}', Colors.blue),
                          _buildStatRow(
                              'Bets Lost:', '${member.betsLost}', Colors.red),
                        ],
                      ),
                      trailing: const Icon(Icons.edit,
                          color: AppColors.lightSecondary),
                      onTap: () => _showUpdateStatsDialog(context, member),
                    ),
                  );
                },
              ),
            );
          } else if (state is AssociationError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            return const Center(child: Text('No members found.'));
          }
        },
      ),
    );
  }

// Method to build a row for a single stat (e.g., Baks Received, Bets Won)
  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Center(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show a dialog for updating stats of a particular member
  void _showUpdateStatsDialog(
      BuildContext context, AssociationMemberModel member) {
    final TextEditingController baksConsumedController =
        TextEditingController(text: member.baksConsumed.toString());
    final TextEditingController baksReceivedController =
        TextEditingController(text: member.baksReceived.toString());
    final TextEditingController betsWonController =
        TextEditingController(text: member.betsWon.toString());
    final TextEditingController betsLostController =
        TextEditingController(text: member.betsLost.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(member.user.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatInputField('Baks Received', baksReceivedController),
              _buildStatInputField('Baks Consumed', baksConsumedController),
              _buildStatInputField('Bets Won', betsWonController),
              _buildStatInputField('Bets Lost', betsLostController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.lightSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final baksConsumed =
                    int.tryParse(baksConsumedController.text) ?? 0;
                final baksReceived =
                    int.tryParse(baksReceivedController.text) ?? 0;
                final betsWon = int.tryParse(betsWonController.text) ?? 0;
                final betsLost = int.tryParse(betsLostController.text) ?? 0;

                // Dispatch the UpdateMemberStats event
                context.read<AssociationBloc>().add(
                      UpdateMemberStats(
                        associationId: widget.associationId,
                        memberId: member.user.id,
                        baksConsumed: baksConsumed,
                        baksReceived: baksReceived,
                        betsWon: betsWon,
                        betsLost: betsLost,
                      ),
                    );

                Navigator.of(context).pop();
              },
              child:
                  const Text('Update', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
