import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/services/notifications_service.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final NotificationsService notificationsService;

  const SplashScreen({super.key, required this.notificationsService});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthentication());
  }

  Future<void> _checkAuthentication() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // Set up Firebase Messaging and FCM token handling for the authenticated user

        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // Request notification permissions
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('User granted notification permission');
          await widget.notificationsService.handleFCMToken(messaging);
        } else {
          print('User declined or did not grant notification permission');
        }

        final associations = await _getAssociations();
        if (associations.isNotEmpty) {
          _navigateToHomeScreen();
        } else {
          _navigateToNoAssociationScreen();
        }
      } else {
        _navigateToLoginScreen();
      }
    } catch (e) {
      print('Error during authentication check: $e');
      _navigateToLoginScreen();
    }
  }

  Future<List<dynamic>> _getAssociations() async {
    try {
      final response = await Supabase.instance.client
          .from('association_members')
          .select()
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id);

      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching associations: $e');
      return [];
    }
  }

  void _navigateToHomeScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _navigateToNoAssociationScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const NoAssociationScreen()),
    );
  }

  void _navigateToLoginScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show a loading spinner
      ),
    );
  }
}
