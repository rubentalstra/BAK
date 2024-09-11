import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationService {
  final supabase = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    await supabase.auth.signUp(email: email, password: password);
  }

  Future<void> loginWithEmailPassword(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Stream<AuthState> authStateChanges() {
    return supabase.auth.onAuthStateChange;
  }
}
