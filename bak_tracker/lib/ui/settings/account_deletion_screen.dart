import 'dart:convert';
import 'package:bak_tracker/core/const/config.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDeletionScreen extends StatelessWidget {
  const AccountDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Deletion'),
      ),
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
                onPressed: () {
                  _showConfirmDeletionDialog(context);
                },
                child: const Text('Request Deletion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: const Text(
              'Are you sure you want to permanently delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                _deleteAccount(context);
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    final dio = Dio(); // Create Dio instance

    try {
      // Call the Edge function to delete the account
      final response = await dio.post(
        '$supabaseUrl/functions/v1/delete-account', // Use the constant supabaseUrl
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer ${supabase.auth.currentSession?.accessToken}', // Pass the access token
          },
        ),
        data: jsonEncode(
            {'userId': userId}), // Send the userId in the request body
      );

      if (response.statusCode == 200) {
        // Account deletion successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account successfully deleted.')),
        );

        // Sign out the user
        await supabase.auth.signOut();

        // Navigate to the LoginScreen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Handle error (show SnackBar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: ${response.data}')),
        );
      }
    } catch (error) {
      // Show SnackBar in case of an unexpected error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }
}
