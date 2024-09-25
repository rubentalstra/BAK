import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/core/utils/locale_utils.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/association_request_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:bak_tracker/ui/settings/user_profile/profile_screen.dart';
import 'package:bak_tracker/ui/widgets/invite_code_input_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/settings/association_settings/association_settings_screen.dart';
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
      body: BlocListener<AssociationBloc, AssociationState>(
        listener: (context, state) {
          if (state is NoAssociationsLeft) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const NoAssociationScreen(),
              ),
              (Route<dynamic> route) => false,
            );
          } else if (state is AssociationLeave) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
            );
          } else if (state is AssociationJoined) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
            );
          } else if (state is AssociationLoaded && state.errorMessage != null) {
            Future.delayed(Duration.zero, () {
              _showErrorSnackBar(context, state.errorMessage!);
            });
            context.read<AssociationBloc>().add(ClearAssociationError());
          } else if (state is AssociationError) {
            Future.delayed(Duration.zero, () {
              _showErrorSnackBar(context, state.message);
            });
            context.read<AssociationBloc>().add(ClearAssociationError());
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('General'),
            ListTile(
              title: const Text('Select Language'),
              subtitle: const Text('Choose your preferred language'),
              trailing: const Icon(Icons.language),
              onTap: () => _showLanguageSelector(context),
            ),
            const Divider(),
            ListTile(
              title: const Text('Profile Settings'),
              subtitle: const Text('Update your profile information'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(),

            // Association settings section
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Association Settings'),
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
                      ListTile(
                        title: const Text('Join Another Association'),
                        subtitle: const Text('Enter an invite code to join'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showInviteCodeModal(context);
                        },
                      ),
                      const Divider(),
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
                      ListTile(
                        title: const Text('Leave Association'),
                        subtitle: const Text('Leave the current association'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showConfirmLeaveDialog(context, state);
                        },
                      ),
                    ],
                  );
                } else if (state is AssociationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Association Actions'),
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
            _buildSectionTitle('Account'),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
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

  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildLanguageOptions(context),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildLanguageOptions(BuildContext context) {
    final currentLocale = context.read<LocaleBloc>().state.locale;
    return AppLocalizations.supportedLocales.map((locale) {
      String localeName = LocaleUtils.getLocaleName(locale.languageCode);
      return RadioListTile<Locale>(
        title: Text(localeName),
        value: locale,
        groupValue: currentLocale,
        onChanged: (selectedLocale) {
          if (selectedLocale != null) {
            context
                .read<LocaleBloc>()
                .add(LocaleChanged(locale: selectedLocale));
            Navigator.of(context).pop();
          }
        },
      );
    }).toList();
  }

  void _showConfirmLeaveDialog(BuildContext context, AssociationLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Leave'),
        content: const Text(
            'Are you sure you want to leave this association? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.lightSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<AssociationBloc>().add(LeaveAssociation(
                    associationId: state.selectedAssociation.id,
                  ));
              Navigator.of(context).pop();
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
