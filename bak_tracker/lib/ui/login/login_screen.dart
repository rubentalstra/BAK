import 'dart:io';
import 'package:bak_tracker/core/themes/colors.dart';
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
      backgroundColor: AppColors.lightPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo at the top of the screen
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icon/bak_tracker_logo.jpg',
                      height: 150.0,
                      width: 150.0,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24.0),
                    const Text(
                      'Welcome to BAK app!',
                      style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Login to continue',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 38.0),

                // Social Login Button
                SupaSocialsAuth(
                  colored: true,
                  nativeGoogleAuthConfig: NativeGoogleAuthConfig(
                    webClientId: Env.webClientId,
                    iosClientId: Env.iosClientId,
                  ),
                  enableNativeAppleAuth: Platform.isIOS ? true : false,
                  socialProviders: Platform.isIOS
                      ? const [OAuthProvider.apple, OAuthProvider.google]
                      : const [OAuthProvider.google],
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
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const MainScreen()),
                          (route) => false,
                        );
                      } else {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const NoAssociationScreen()),
                          (route) => false,
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

                const SizedBox(height: 48.0),
                // Footer text or any additional options
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
