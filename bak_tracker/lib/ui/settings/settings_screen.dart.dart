import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/theme/theme_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/bloc/notifications/notifications_bloc.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart'; // For iOS-specific widgets

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    // Use CupertinoPageScaffold for iOS and Scaffold for Android
    return isIOS
        ? _buildCupertinoPageScaffold(context)
        : _buildMaterialScaffold(context);
  }

  // Native CupertinoPageScaffold for iOS
  Widget _buildCupertinoPageScaffold(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Settings'),
      ),
      child: SafeArea(
        child: _buildCupertinoSettings(context),
      ),
    );
  }

  // Material Scaffold for Android
  Widget _buildMaterialScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _buildMaterialSettings(context),
    );
  }

  // Material design (Android) settings screen
  Widget _buildMaterialSettings(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Theme Change (Light, Dark, System Default)
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            return ListTile(
              title: const Text('Theme'),
              subtitle: const Text('Light / Dark / System Default'),
              trailing: DropdownButton<ThemeMode>(
                value: state.themeMode,
                items: const [
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text('System Default')),
                ],
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    context
                        .read<ThemeBloc>()
                        .add(ThemeChanged(themeMode: value));
                  }
                },
              ),
            );
          },
        ),

        // Locale Change (Language)
        BlocBuilder<LocaleBloc, LocaleState>(
          builder: (context, state) {
            return ListTile(
              title: const Text('Language'),
              subtitle: const Text('Select app language'),
              trailing: DropdownButton<String>(
                value: state.locale.languageCode == 'en' ? 'English' : 'Dutch',
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Dutch', child: Text('Dutch')),
                ],
                onChanged: (value) {
                  context.read<LocaleBloc>().add(LocaleChanged(
                      locale: value == 'English'
                          ? const Locale('en')
                          : const Locale('nl')));
                },
              ),
            );
          },
        ),

        // Notifications Toggle
        BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            return ListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Enable or disable notifications'),
              trailing: Switch(
                value: state.isEnabled,
                onChanged: (value) {
                  context.read<NotificationsBloc>().add(
                        NotificationsToggled(isEnabled: value),
                      );
                },
              ),
            );
          },
        ),

        // Logout Button
        ElevatedButton(
          onPressed: () {
            context.read<AuthenticationBloc>().signOut(); // Sign out logic
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }

  // Cupertino (iOS) settings screen
  Widget _buildCupertinoSettings(BuildContext context) {
    return ListView(
      children: [
        CupertinoFormSection(
          header: const Text('Appearance'),
          children: [
            // Theme Change (Light, Dark, System Default)
            BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return CupertinoFormRow(
                  prefix: const Text('Theme'),
                  child: CupertinoButton(
                    child: Text(
                      state.themeMode == ThemeMode.system
                          ? 'System Default'
                          : state.themeMode == ThemeMode.dark
                              ? 'Dark'
                              : 'Light',
                    ),
                    onPressed: () {
                      _showThemePicker(context, state.themeMode);
                    },
                  ),
                );
              },
            ),
          ],
        ),
        CupertinoFormSection(
          header: const Text('Preferences'),
          children: [
            // Language Change
            BlocBuilder<LocaleBloc, LocaleState>(
              builder: (context, state) {
                return CupertinoFormRow(
                  prefix: const Text('Language'),
                  child: CupertinoButton(
                    onPressed: () {
                      _showLanguagePicker(context, state.locale.languageCode);
                    },
                    child: Text(state.locale.languageCode == 'en'
                        ? 'English'
                        : 'Dutch'),
                  ),
                );
              },
            ),

            // Notifications Toggle
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                return CupertinoFormRow(
                  prefix: const Text('Notifications'),
                  child: CupertinoSwitch(
                    value: state.isEnabled,
                    onChanged: (value) {
                      context.read<NotificationsBloc>().add(
                            NotificationsToggled(isEnabled: value),
                          );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        CupertinoFormSection(
          header: const Text('Account'),
          children: [
            // Logout
            CupertinoFormRow(
              prefix: const Text('Logout'),
              child: CupertinoButton(
                onPressed: () {
                  context
                      .read<AuthenticationBloc>()
                      .signOut(); // Sign out logic
                  Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Logout',
                    style: TextStyle(color: CupertinoColors.destructiveRed)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper function to show Theme Picker for iOS
  void _showThemePicker(BuildContext context, ThemeMode currentMode) {
    final options = ['Light', 'Dark', 'System Default'];
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: currentMode == ThemeMode.system
                  ? 2
                  : currentMode == ThemeMode.dark
                      ? 1
                      : 0,
            ),
            itemExtent: 32.0,
            onSelectedItemChanged: (index) {
              final themeMode = index == 0
                  ? ThemeMode.light
                  : index == 1
                      ? ThemeMode.dark
                      : ThemeMode.system;
              context.read<ThemeBloc>().add(ThemeChanged(themeMode: themeMode));
            },
            children: options.map((option) => Text(option)).toList(),
          ),
        );
      },
    );
  }

  // Helper function to show Language Picker for iOS
  void _showLanguagePicker(BuildContext context, String selectedLanguage) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: CupertinoPicker(
            backgroundColor: CupertinoColors.systemBackground,
            itemExtent: 32.0,
            onSelectedItemChanged: (int index) {
              final selectedLocale =
                  index == 0 ? const Locale('en') : const Locale('nl');
              context
                  .read<LocaleBloc>()
                  .add(LocaleChanged(locale: selectedLocale));
            },
            children: const [
              Text('English'),
              Text('Dutch'),
            ],
          ),
        );
      },
    );
  }
}
