import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define the custom LocalStorage implementation using flutter_secure_storage
class MySecureStorage extends LocalStorage {
  final _storage = const FlutterSecureStorage();

  // Initialize if any setup is needed (empty in this case)
  @override
  Future<void> initialize() async {}

  // Get the access token from secure storage
  @override
  Future<String?> accessToken() async {
    return _storage.read(key: supabasePersistSessionKey);
  }

  // Check if an access token exists in secure storage
  @override
  Future<bool> hasAccessToken() async {
    return _storage.containsKey(key: supabasePersistSessionKey);
  }

  // Persist the session string in secure storage
  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(
        key: supabasePersistSessionKey, value: persistSessionString);
  }

  // Remove the persisted session from secure storage
  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: supabasePersistSessionKey);
  }
}
