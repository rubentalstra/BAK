// lib/env/env.dart

import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  // Supabase-related environment variables (obfuscated)
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static final String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static final String supabaseAnonKey = _Env.supabaseAnonKey;

  // Google OAuth Client IDs (obfuscated)
  @EnviedField(varName: 'YOUR_WEB_CLIENT_ID', obfuscate: true)
  static final String webClientId = _Env.webClientId;

  @EnviedField(varName: 'YOUR_IOS_CLIENT_ID', obfuscate: true)
  static final String iosClientId = _Env.iosClientId;
}
