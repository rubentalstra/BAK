import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bak_tracker/env/env.dart';
import 'auth_state.dart';

class AuthenticationBloc extends Cubit<AuthenticationState> {
  AuthenticationBloc() : super(AuthenticationInitial());

  Future<void> signInWithGoogle() async {
    try {
      emit(AuthenticationLoading());

      // Use the Env class from envied to access the client IDs
      var webClientId = Env.webClientId; // Get Web Client ID from Env class
      var iosClientId = Env.iosClientId; // Get iOS Client ID from Env class

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google sign-in was canceled by the user.';
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw 'Google sign-in failed: No tokens available.';
      }

      // Use Supabase sign-in with ID Token and Access Token
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      emit(AuthenticationSuccess());
    } catch (e) {
      emit(AuthenticationFailure(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      // Clear the selected association from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_association');

      emit(AuthenticationSignedOut());
    } catch (e) {
      emit(AuthenticationFailure('Sign out failed: ${e.toString()}'));
    }
  }
}
