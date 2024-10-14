import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/core/utils/locale_utils.dart';
import 'package:bak_tracker/main.dart';
import 'package:bak_tracker/services/pdf_upload_service.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/legal/privacy_policy_screen.dart';
import 'package:bak_tracker/ui/legal/terms_conditions_screen.dart';
import 'package:bak_tracker/ui/settings/association_request_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:bak_tracker/ui/settings/account_deletion_screen.dart';
import 'package:bak_tracker/ui/settings/user_profile/profile_screen.dart';
import 'package:bak_tracker/ui/widgets/invite_code_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _isNotificationEnabled = status.isGranted;
    });
  }

  Future<void> _onNotificationToggle(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() {
          _isNotificationEnabled = true;
        });
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else {
      setState(() {
        _isNotificationEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket),
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
              icon: FontAwesomeIcons.bell,
              title: 'Enable Notifications',
              subtitle: 'Allow notifications from the app',
              onTap: () {
                _onNotificationToggle(!_isNotificationEnabled);
              },
              trailing: Switch(
                value: _isNotificationEnabled,
                onChanged: _onNotificationToggle,
              ),
            ),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.circleUser,
              title: 'Profile Settings',
              subtitle: 'Update your profile information',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            BlocBuilder<AssociationBloc, AssociationState>(
              builder: (context, state) {
                if (state is AssociationLoaded) {
                  return _buildAssociationActions(context, state);
                } else if (state is NoAssociationsLeft) {
                  return _buildJoinOrCreateAssociationActions(context);
                } else if (state is AssociationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return _buildJoinOrCreateAssociationActions(context);
                }
              },
            ),
            _buildSectionHeader('Legal'),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.shieldHalved,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.fileContract,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms and conditions',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TermsAndConditionsScreen(),
                  ),
                );
              },
            ),
            _buildSectionHeader('Account'),
            _buildOptionCard(
              context,
              icon: FontAwesomeIcons.userMinus,
              title: 'Request Account Deletion',
              subtitle: 'Permanently delete your account',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountDeletionScreen(),
                  ),
                );
              },
            ),
            _buildVersionInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociationActions(
      BuildContext context, AssociationLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Association Settings'),
        _buildOptionCard(
          context,
          icon: FontAwesomeIcons.filePdf,
          title: 'View BAK Regulations',
          subtitle: 'Read the association\'s regulations',
          onTap: () => _handleViewAssociationPdf(context, state),
        ),
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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AssociationRequestScreen(),
              ),
            );
          },
        ),
        _buildOptionCard(
          context,
          icon: FontAwesomeIcons.personWalkingArrowRight,
          title: 'Leave Association',
          subtitle: 'Leave the current association',
          onTap: () => _showConfirmLeaveDialog(context, state),
        ),
      ],
    );
  }

  Widget _buildJoinOrCreateAssociationActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Association Actions'),
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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AssociationRequestScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  // Handle viewing the association's PDF document
  void _handleViewAssociationPdf(
      BuildContext context, AssociationLoaded state) async {
    final pdfService = PDFUploadService(Supabase.instance.client);

    // Fetch the association's PDF file name and ID
    final pdfFileName = state.selectedAssociation.bakRegulations;
    final associationId = state.selectedAssociation.id;

    if (pdfFileName == null || pdfFileName.isEmpty) {
      _showErrorSnackBar(
          context, 'No Regulation uploaded for this association.');
      return;
    }

    try {
      // Fetch or download the PDF
      final pdfFile =
          await pdfService.fetchOrDownloadPdf(pdfFileName, associationId);

      if (pdfFile != null) {
        // Open the PDF for reading
        await pdfService.openPdf(context, pdfFile);
      } else {
        _showErrorSnackBar(context, 'Failed to retrieve the PDF.');
      }
    } catch (e) {
      print('Error during PDF download or opening: $e');
      _showErrorSnackBar(context, 'An error occurred while opening the PDF.');
    }
  }

  // Section Header Widget
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

  // Option Card Widget
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
        leading: Icon(icon, color: AppColors.lightSecondary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // Version Info
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
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Other utility and widget methods here...

  Widget _buildJoinAssociationActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Association Actions'),
        _buildListTile(
          context,
          title: 'Join Association',
          subtitle: 'Enter an invite code to join',
          icon: FontAwesomeIcons.circlePlus,
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
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
      leading: FaIcon(icon, color: AppColors.lightSecondary),
      trailing: const Icon(Icons.chevron_right),
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

  // Method to handle the logout functionality
  void _handleLogout(BuildContext context) {
    context.read<AuthenticationBloc>().signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Method to handle association state changes
  void _handleAssociationStateChanges(
      BuildContext context, AssociationState state) {
    if (state is NoAssociationsLeft) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NoAssociationScreen()),
        (Route<dynamic> route) => false,
      );
    } else if (state is AssociationLeft || state is AssociationJoined) {
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
