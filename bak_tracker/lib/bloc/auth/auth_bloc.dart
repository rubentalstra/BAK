import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_state.dart';

class AuthenticationBloc extends Cubit<AuthenticationState> {
  AuthenticationBloc() : super(AuthenticationInitial());

  Future<void> signInWithGoogle() async {
    try {
      emit(AuthenticationLoading());

      var webClientId = dotenv.env['YOUR_WEB_CLIENT_ID']!;
      var iosClientId = dotenv.env['YOUR_IOS_CLIENT_ID']!;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw 'Google sign-in failed: No tokens available.';
      }

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
    await Supabase.instance.client.auth.signOut();

    // Clear the selected association from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_association');

    emit(AuthenticationSignedOut());
  }
}
