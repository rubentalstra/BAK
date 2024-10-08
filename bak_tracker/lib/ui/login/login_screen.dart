import 'package:bak_tracker/services/notifications_service.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:bak_tracker/env/env.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Function to check if the user is part of any association
  Future<bool> _checkUserAssociation() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return false; // User is not logged in
      }

      final response = await Supabase.instance.client
          .from('association_members')
          .select()
          .eq('user_id', userId);

      return response.isNotEmpty; // True if user is part of an association
    } catch (e) {
      print('Error fetching user association: $e');
      return false; // Error occurred, assume no association
    }
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
              webClientId: Env.webClientId,
              iosClientId: Env.iosClientId,
            ),
            enableNativeAppleAuth: false,
            socialProviders: const [OAuthProvider.google],
            redirectUrl: kIsWeb
                ? null
                : 'https://iywlypvipqaibumbgsyf.supabase.co/auth/v1/callback',
            onSuccess: (Session session) async {
              try {
                // Automatically handle FCM token after login
                FirebaseMessaging messaging = FirebaseMessaging.instance;
                final FlutterLocalNotificationsPlugin
                    flutterLocalNotificationsPlugin =
                    FlutterLocalNotificationsPlugin();
                final notificationsService =
                    NotificationsService(flutterLocalNotificationsPlugin);

                // Handle FCM token and notifications registration
                await notificationsService.handleFCMToken(messaging);

                // Check if the user belongs to an association
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
              } catch (error) {
                print('Login error details: $error'); // Log error details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Login Failed: $error')),
                );
              }
            },
            onError: (error) {
              print('Login error details: $error'); // Log error details
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
