import 'package:bak_tracker/services/notifications_service.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:bak_tracker/env/env.dart'; // Import generated Env class from envied

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Function to check if the user is part of any association
  Future<bool> _checkUserAssociation() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('User is not logged in.');
        return false;
      }

      final response = await Supabase.instance.client
          .from('association_members')
          .select()
          .eq('user_id', userId);

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
          SupaSocialsAuth(
            colored: true,
            nativeGoogleAuthConfig: NativeGoogleAuthConfig(
              webClientId: Env.webClientId, // Using Env class for client ID
              iosClientId: Env.iosClientId, // Using Env class for iOS client ID
            ),
            enableNativeAppleAuth: false,
            socialProviders: const [OAuthProvider.google],
            redirectUrl: kIsWeb
                ? null
                : 'https://iywlypvipqaibumbgsyf.supabase.co/auth/v1/callback',
            onSuccess: (Session session) async {
              // Automatically handle FCM token after login
              FirebaseMessaging messaging = FirebaseMessaging.instance;
              // Initialize Local Notifications Plugin
              final FlutterLocalNotificationsPlugin
                  flutterLocalNotificationsPlugin =
                  FlutterLocalNotificationsPlugin();
              final notificationsService =
                  NotificationsService(flutterLocalNotificationsPlugin);

              // Await the FCM token handling to ensure it completes before navigating
              await notificationsService.handleFCMToken(messaging);

              bool isPartOfAssociation = await _checkUserAssociation();

              // Navigate to the appropriate screen based on association status
              if (isPartOfAssociation) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const NoAssociationScreen()),
                );
              }
            },
            onError: (error) {
              print('Login error details: $error'); // Detailed error logs
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
