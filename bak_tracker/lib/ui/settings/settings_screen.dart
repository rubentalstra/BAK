import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/core/utils/locale_utils.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/association_request_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:bak_tracker/ui/settings/account_deletion_screen.dart';
import 'package:bak_tracker/ui/settings/user_profile/profile_screen.dart';
import 'package:bak_tracker/ui/widgets/invite_code_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _handleLogout(context);
            },
          ),
        ],
      ),
      body: BlocListener<AssociationBloc, AssociationState>(
        listener: (context, state) {
          _handleAssociationStateChanges(context, state);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('General'),
            _buildListTile(
              context,
              title: 'Select Language',
              subtitle: 'Choose your preferred language',
              icon: Icons.language,
              onTap: () => _showLanguageSelector(context),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              title: 'Profile Settings',
              subtitle: 'Update your profile information',
              icon: Icons.chevron_right,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            _buildDivider(),
            BlocBuilder<AssociationBloc, AssociationState>(
              builder: (context, state) {
                if (state is AssociationLoaded) {
                  return _buildAssociationSettings(context, state);
                } else if (state is AssociationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return _buildJoinAssociationActions(context);
                }
              },
            ),
            _buildSectionTitle('Account'),
            _buildListTile(
              context,
              title: 'Request Account Deletion',
              subtitle: 'Permanently delete your account',
              icon: Icons.chevron_right,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AccountDeletionScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthenticationBloc>().signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _handleAssociationStateChanges(
      BuildContext context, AssociationState state) {
    if (state is NoAssociationsLeft) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NoAssociationScreen()),
        (Route<dynamic> route) => false,
      );
    } else if (state is AssociationLeave || state is AssociationJoined) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } else if (state is AssociationLoaded && state.errorMessage != null) {
      _showErrorSnackBar(context, state.errorMessage!);
      context.read<AssociationBloc>().add(ClearAssociationError());
    } else if (state is AssociationError) {
      _showErrorSnackBar(context, state.message);
      context.read<AssociationBloc>().add(ClearAssociationError());
    }
  }

  Widget _buildAssociationSettings(
      BuildContext context, AssociationLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Association Settings'),
        _buildListTile(
          context,
          title: 'Join Another Association',
          subtitle: 'Enter an invite code to join',
          icon: Icons.chevron_right,
          onTap: () => _showInviteCodeModal(context),
        ),
        _buildDivider(),
        _buildListTile(
          context,
          title: 'Create Association',
          subtitle: 'Create a new association',
          icon: Icons.chevron_right,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AssociationRequestScreen()),
            );
          },
        ),
        _buildDivider(),
        _buildListTile(
          context,
          title: 'Leave Association',
          subtitle: 'Leave the current association',
          icon: Icons.chevron_right,
          onTap: () => _showConfirmLeaveDialog(context, state),
        ),
      ],
    );
  }

  Widget _buildJoinAssociationActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Association Actions'),
        _buildListTile(
          context,
          title: 'Join Association',
          subtitle: 'Enter an invite code to join',
          icon: Icons.chevron_right,
          onTap: () => _showInviteCodeModal(context),
        ),
        _buildDivider(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required void Function()? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(icon),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider();

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _showInviteCodeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
      final localeName = LocaleUtils.getLocaleName(locale.languageCode);
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.lightSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<AssociationBloc>().add(LeaveAssociation(
                  associationId: state.selectedAssociation.id));
              Navigator.of(context).pop();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
