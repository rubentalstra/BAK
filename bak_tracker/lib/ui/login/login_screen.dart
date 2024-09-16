import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Function to check if the user is part of any association
  Future<bool> _checkUserAssociation() async {
    try {
      final response = await Supabase.instance.client
          .from('association_members')
          .select()
          .eq(
              'id',
              Supabase.instance.client.auth.currentUser!
                  .id); // Now using the user_id from the users table

      if (response.isNotEmpty) {
        return true; // User is part of at least one association
      }
    } catch (e) {
      print('Error fetching user association: $e');
    }
    return false; // No association found or an error occurred
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Google Social Sign-in with SupaSocialsAuth
          SupaSocialsAuth(
            colored: true, // Enable colored Google button
            nativeGoogleAuthConfig: NativeGoogleAuthConfig(
              webClientId: dotenv.env[
                  'YOUR_WEB_CLIENT_ID']!, // Replace with your Google Web Client ID
              iosClientId: dotenv.env[
                  'YOUR_IOS_CLIENT_ID']!, // Replace with your Google iOS Client ID
            ),
            enableNativeAppleAuth: false, // Only Google login enabled
            socialProviders: const [
              OAuthProvider.google
            ], // Only Google as the provider
            redirectUrl: kIsWeb
                ? null
                : 'https://iywlypvipqaibumbgsyf.supabase.co/auth/v1/callback',
            onSuccess: (Session session) async {
              // Check if the user is part of an association
              bool isPartOfAssociation = await _checkUserAssociation();

              if (isPartOfAssociation) {
                // Navigate to the HomeScreen if part of an association
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              } else {
                // Navigate to NoAssociationScreen if not part of any association
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const NoAssociationScreen()),
                );
              }
            },
            onError: (error) {
              print('Login error details: $error'); // Add detailed error logs
              // Show an error message if login fails
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login Failed: $error')),
              );
            },
          ),
        ],
      ),
    );
  }
}
