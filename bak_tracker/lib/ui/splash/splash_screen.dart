import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:bak_tracker/ui/login/login_screen.dart'; // Import the LoginScreen
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // After the build phase, run authentication logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Fetch the associations the user is part of
      final associations = await _getAssociations();
      if (associations.isNotEmpty) {
        _navigateToHomeScreen();
      } else {
        _navigateToNoAssociationScreen();
      }
    } else {
      // User is not logged in, navigate to the LoginScreen
      _navigateToLoginScreen();
    }
  }

  Future<List<dynamic>> _getAssociations() async {
    try {
      // Fetch the user's associations from 'association_members' table
      final List<dynamic> response =
          await Supabase.instance.client.from('association_members').select();
      return response;
    } catch (e) {
      print('Error fetching associations: $e');
      return [];
    }
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _navigateToNoAssociationScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const NoAssociationScreen()),
    );
  }

  void _navigateToLoginScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // No UI needed as splash is handled natively
  }
}
