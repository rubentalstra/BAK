import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:bak_tracker/ui/settings/change_display_name_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            title: const Text(
              'Display Name',
            ),
            subtitle: const Text(
              'Change your display name',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ), // Themed icon color
            onTap: () {
              // Navigate to change display name screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangeDisplayNameScreen(),
                ),
              );
            },
          ),
          const Divider(), // Use themed divider color

          // Locale Change (Language)
          BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, state) {
              return ListTile(
                title: const Text(
                  'Language',
                ),
                subtitle: const Text(
                  'Select app language',
                ),
                trailing: DropdownButton<String>(
                  value:
                      state.locale.languageCode == 'en' ? 'English' : 'Dutch',

                  icon: const Icon(
                    Icons.language,
                  ), // Themed icon color
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
          const Divider(), // Use themed divider color

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
      ),
    );
  }
}
