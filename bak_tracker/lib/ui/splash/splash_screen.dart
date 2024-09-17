import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      final associations = await _getAssociations();
      if (associations.isNotEmpty) {
        _navigateToHomeScreen();
      } else {
        _navigateToNoAssociationScreen();
      }
    } else {
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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show a loading spinner
      ),
    );
  }
}
