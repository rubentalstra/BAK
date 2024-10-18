import 'package:bak_tracker/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabaseClient;

  UserService(this._supabaseClient);

  /// Fetches the user by ID along with their achievements
  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select(
              '*, user_achievements (id, assigned_at, achievement_id(id, name, description, created_at))')
          .eq('id', userId)
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the user data in the database
  Future<void> updateUser(UserModel user) async {
    try {
      await _supabaseClient
          .from('users')
          .update(user.toMap())
          .eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Logs alcohol consumption and updates the user's streak information
  Future<UserModel> logAlcoholConsumption(
      UserModel user, String alcoholType) async {
    final now = DateTime.now();

    // Calculate the streak update logic
    int newStreak = user.alcoholStreak;
    int highestStreak = user.highestAlcoholStreak;

    if (user.lastDrinkConsumedAt != null) {
      final timeSinceLastDrink = now.difference(user.lastDrinkConsumedAt!);
      if (timeSinceLastDrink.inHours <= 36) {
        newStreak += 1;
        if (newStreak > highestStreak) {
          highestStreak = newStreak;
        }
      } else {
        newStreak = 1; // Reset streak if more than 36 hours
      }
    } else {
      newStreak = 1; // Starting the streak for the first time
    }

    try {
      await _supabaseClient.from('users').update({
        'alcohol_streak': newStreak,
        'highest_alcohol_streak': highestStreak,
        'last_drink_consumed_at': now.toIso8601String(),
      }).eq('id', user.id);

      return getUserById(user.id); // Fetch the updated user
    } catch (e) {
      rethrow;
    }
  }

  /// Toggles general notification settings
  Future<void> toggleNotifications(String userId, bool isEnabled) async {
    try {
      await _supabaseClient.from('users').update({
        'notifications_enabled': isEnabled,
      }).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggles streak notification settings
  Future<void> toggleStreakNotifications(String userId, bool isEnabled) async {
    try {
      await _supabaseClient.from('users').update({
        'streak_notification_enabled': isEnabled,
      }).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches whether notifications are enabled for the user
  Future<bool> areNotificationsEnabled(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select('notifications_enabled')
          .eq('id', userId)
          .single();

      return response['notifications_enabled'] as bool;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches whether streak notifications are enabled for the user
  Future<bool> areStreakNotificationsEnabled(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select('streak_notification_enabled')
          .eq('id', userId)
          .single();

      return response['streak_notification_enabled'] as bool;
    } catch (e) {
      rethrow;
    }
  }
}
