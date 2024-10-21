import 'package:bak_tracker/core/const/drink_types.dart';
import 'package:bak_tracker/models/alcohol_tracking_model.dart';
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

  // Log alcohol consumption and update streaks
  Future<UserModel> logAlcoholConsumption(
    UserModel user,
    String alcoholType,
  ) async {
    final DateTime now = DateTime.now();

    // Initialize streak update variables
    int newStreak = user.alcoholStreak;
    int highestStreak = user.highestAlcoholStreak;
    bool streakUpdated = false;

    // Check if user has logged drinks before
    if (user.lastDrinkConsumedAt != null) {
      final lastDrinkDate = user.lastDrinkConsumedAt!;

      // Check if it's a new day (i.e., after midnight)
      if (now.day != lastDrinkDate.day ||
          now.isAfter(DateTime(lastDrinkDate.year, lastDrinkDate.month,
              lastDrinkDate.day, 23, 59, 59))) {
        // Increment the current streak
        newStreak += 1;

        // Only increment the highest streak if it's equal to the current streak
        if (newStreak > highestStreak) {
          highestStreak += 1;
        }

        streakUpdated = true;
      } else {
        // No streak increment if it's the same day
        newStreak = user.alcoholStreak;
      }
    } else {
      // First time logging alcohol consumption starts a new streak
      newStreak = 1;
      highestStreak = 1;
      streakUpdated = true;
    }

    try {
      // Log the alcohol consumption in the alcohol_tracking table
      await _supabaseClient.from('alcohol_tracking').insert({
        'user_id': user.id,
        'drink_type': alcoholType,
        'drink_amount': 1,
        'consumed_at': now.toIso8601String(),
      });

      // Only update the last_drink_consumed_at and streaks when necessary
      if (streakUpdated) {
        await _supabaseClient.from('users').update({
          'alcohol_streak': newStreak,
          'highest_alcohol_streak': highestStreak,
          'last_drink_consumed_at': now.toIso8601String(),
        }).eq('id', user.id);
      }

      // Return the updated user data
      return getUserById(user.id);
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

  // Fetch alcohol logs for the user
  Future<List<AlcoholTrackingModel>> getAlcoholLogs(String userId) async {
    final response = await _supabaseClient
        .from('alcohol_tracking')
        .select('*')
        .eq('user_id', userId)
        .order('consumed_at', ascending: false);

    return response.map<AlcoholTrackingModel>((data) {
      return AlcoholTrackingModel.fromMap(data);
    }).toList();
  }

// Fetch the total consumption per drink type for the user
  Future<Map<DrinkType, int>> getTotalConsumption(String userId) async {
    try {
      final response = await _supabaseClient
          .rpc('sum_drink_amounts', params: {'user_id_input': userId});

      if (response == null || response.isEmpty) {
        return {};
      }

      // Using a for-loop instead of fold to handle non-nullable types safely
      Map<DrinkType, int> consumptionMap = {};

      for (var record in response) {
        final drinkTypeString = record['drink_type'] as String?;
        final totalAmount = record['total_amount'] as int? ?? 0;

        if (drinkTypeString != null && totalAmount > 0) {
          // Convert the string to the appropriate DrinkType enum
          final drinkType = DrinkTypeExtension.fromString(drinkTypeString);
          consumptionMap[drinkType] = totalAmount;
        }
      }

      print('Consumption map: $consumptionMap');

      return consumptionMap;
    } catch (e) {
      throw Exception('Failed to fetch total consumption: $e');
    }
  }
}
