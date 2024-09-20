import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/ui/no_association/association_request_screen.dart';
import 'package:bak_tracker/ui/widgets/invite_code_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/settings/association_settings/association_settings_screen.dart';
import 'package:bak_tracker/ui/settings/change_display_name_screen.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Change Display Name Option
          ListTile(
            title: const Text('Display Name'),
            subtitle: const Text('Change your display name'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangeDisplayNameScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // BlocBuilder to conditionally show association-related settings
          BlocBuilder<AssociationBloc, AssociationState>(
            builder: (context, state) {
              if (state is AssociationLoaded) {
                final memberData = state.memberData;

                bool hasAssociationPermissions =
                    memberData.canManagePermissions ||
                        memberData.canInviteMembers ||
                        memberData.canRemoveMembers ||
                        memberData.canManageRoles ||
                        memberData.canManageBaks ||
                        memberData.canApproveBaks;

                return Column(
                  children: [
                    // Display error message if any
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          state.errorMessage!,
                          style:
                              const TextStyle(color: AppColors.lightSecondary),
                        ),
                      ),
                    // Conditionally display the Association Settings option
                    if (hasAssociationPermissions)
                      ListTile(
                        title: const Text('Association Settings'),
                        subtitle: const Text('Manage association settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AssociationSettingsScreen(
                                memberData: memberData,
                                associationId: state.selectedAssociation.id,
                              ),
                            ),
                          );
                        },
                      ),
                    if (hasAssociationPermissions) const Divider(),

                    // Option to Join Another Association
                    ListTile(
                      title: const Text('Join Another Association'),
                      subtitle: const Text('Enter an invite code to join'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showInviteCodeModal(context);
                      },
                    ),
                    const Divider(),

                    // Option to Create Association
                    ListTile(
                      title: const Text('Create Association'),
                      subtitle: const Text('Create a new association'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AssociationRequestScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),

                    // Option to Leave Association
                    ListTile(
                      title: const Text('Leave Association'),
                      subtitle: const Text('Leave the current association'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Show a confirmation dialog before leaving
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Leave'),
                            content: const Text(
                                'Are you sure you want to leave this association? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Dispatch the leave association event
                                  context.read<AssociationBloc>().add(
                                      LeaveAssociation(
                                          associationId:
                                              state.selectedAssociation.id));

                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: const Text('Leave'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              } else if (state is AssociationLoading) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return Column(
                  children: [
                    // Option to Join Association
                    ListTile(
                      title: const Text('Join Association'),
                      subtitle: const Text('Enter an invite code to join'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showInviteCodeModal(context);
                      },
                    ),
                    const Divider(),
                  ],
                );
              }
            },
          ),

          // Logout Button (always available)
          ElevatedButton(
            onPressed: () {
              context.read<AuthenticationBloc>().signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showInviteCodeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const InviteCodeInputWidget(),
        );
      },
    );
  }
}
