import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/ui/widgets/invite_code_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/settings/association_settings_screen.dart';
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
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            final memberData = state.memberData;

            bool hasAssociationPermissions = memberData.canInviteMembers ||
                memberData.canRemoveMembers ||
                memberData.canUpdateRole ||
                memberData.canUpdateBakAmount ||
                memberData.canApproveBakTaken;

            return ListView(
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
                            associationId: state.selectedAssociation
                                .id, // Pass the association ID if needed
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

                // Logout Button
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthenticationBloc>().signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Logout'),
                ),
              ],
            );
          } else if (state is AssociationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('No association selected.'));
          }
        },
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
          child: InviteCodeInputWidget(
            onCodeSubmitted: (inviteCode) {
              // Handle the invite code submission
              // Example: Call a Bloc or API to join the association
              print('Invite Code: $inviteCode');
              // Perform necessary actions with the invite code
            },
          ),
        );
      },
    );
  }
}
