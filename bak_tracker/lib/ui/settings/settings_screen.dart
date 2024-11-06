import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/core/utils/locale_utils.dart';
import 'package:bak_tracker/main.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/legal/privacy_policy_screen.dart';
import 'package:bak_tracker/ui/legal/terms_conditions_screen.dart';
import 'package:bak_tracker/ui/settings/association_request_screen.dart';
import 'package:bak_tracker/ui/settings/account_deletion_screen.dart';
import 'package:bak_tracker/ui/settings/user_profile/profile_screen.dart';
import 'package:bak_tracker/ui/widgets/invite_code_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocListener<AssociationBloc, AssociationState>(
        listener: (context, state) =>
            _handleAssociationStateChanges(context, state),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader('General'),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.language,
              title: 'Select Language',
              subtitle: 'Choose your preferred language',
              onTap: () => _showLanguageSelector(context),
            ),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.circleUser,
              title: 'Profile Settings',
              subtitle: 'Update your profile information',
              onTap: () => _navigateTo(context, const EditProfileScreen()),
            ),
            _buildSectionHeader('Join or Create Association'),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.circlePlus,
              title: 'Join Association',
              subtitle: 'Enter an invite code to join',
              onTap: () => _showInviteCodeModal(context),
            ),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.sitemap,
              title: 'Create Association',
              subtitle: 'Create a new association',
              onTap: () =>
                  _navigateTo(context, const AssociationRequestScreen()),
            ),
            _buildSectionHeader('Legal'),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.shieldHalved,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () => _navigateTo(context, const PrivacyPolicyScreen()),
            ),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.fileContract,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms and conditions',
              onTap: () =>
                  _navigateTo(context, const TermsAndConditionsScreen()),
            ),
            _buildSectionHeader('Account'),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.userMinus,
              title: 'Request Account Deletion',
              subtitle: 'Permanently delete your account',
              onTap: () => _navigateTo(context, const AccountDeletionScreen()),
            ),
            _buildVersionInfo(context),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Settings'),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket),
          tooltip: 'Logout',
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  void _handleAssociationStateChanges(
      BuildContext context, AssociationState state) {
    if (state is AssociationJoined) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } else if (state is AssociationLoaded && state.errorMessage != null) {
      _showErrorSnackBar(context, state.errorMessage!);
      context.read<AssociationBloc>().add(ClearAssociationError());
    } else if (state is AssociationError) {
      _showErrorSnackBar(context, state.message);
      context.read<AssociationBloc>().add(ClearAssociationError());
    }
  }

  // Helper widget for the section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.lightSecondary,
        ),
      ),
    );
  }

  // Helper method to build the option card
  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.lightSecondary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // Helper method to navigate to screens
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  // Show error SnackBar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // Show invite code modal
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

  // Language selector dialog
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

  // Language options
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

  Future<void> _handleLogout(BuildContext context) async {
    final isLogoutConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels logout
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User confirms logout
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ],
        );
      },
    );

    if (isLogoutConfirmed == true) {
      // Proceed with logout if the user confirms
      await context.read<AuthenticationBloc>().signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Version information
  Widget _buildVersionInfo(BuildContext context) {
    final appVersion = appInfoService.appVersion;
    final buildNumber = appInfoService.buildNumber;
    final versionDisplay = '$appVersion+$buildNumber';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'App version: $versionDisplay',
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
