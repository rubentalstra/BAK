import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDeletionScreen extends StatelessWidget {
  const AccountDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Deletion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Important Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Deleting your account is permanent and cannot be undone. All of your data will be erased. Please make sure this is what you want to do.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _showConfirmDeletionDialog(context),
                child: const Text('Request Deletion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog before deletion
  void _showConfirmDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => _deleteAccount(context),
              child: const Text('Delete Account',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  // Delete the account using Supabase Edge function
  Future<void> _deleteAccount(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final sessionToken = supabase.auth.currentSession?.accessToken;

    try {
      final res = await supabase.functions.invoke(
        'delete-account',
        headers: {
          'Authorization': 'Bearer $sessionToken',
        },
      );

      if (res.status == 200) {
        _showSnackBar(context, 'Account successfully deleted.');

        // Sign out and navigate to LoginScreen
        AuthenticationBloc().signOut();
        _navigateToLoginScreen(context);
      } else {
        _showSnackBar(context, 'Error deleting account: ${res.data}');
      }
    } catch (error) {
      _showSnackBar(context, 'An error occurred: $error');
    }
  }

  // Helper method to show a SnackBar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Navigate to LoginScreen and remove all previous routes
  void _navigateToLoginScreen(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
