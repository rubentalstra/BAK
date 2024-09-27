import 'package:supabase_flutter/supabase_flutter.dart';

class BakService {
  // Method to send a 'Bak'
  static Future<void> sendBak({
    required String receiverId,
    required String associationId,
    required int amount,
    required String reason,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      // Fetch the giver's data
      final userResponse =
          await supabase.from('users').select('name').eq('id', userId).single();
      final giverName = userResponse['name'];

      // Insert the Bak into 'bak_send' table
      await supabase.from('bak_send').insert({
        'giver_id': userId,
        'receiver_id': receiverId,
        'association_id': associationId,
        'amount': amount,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notification to the receiver
      await _insertNotification(
        userId: receiverId,
        title: 'You received a Bak from $giverName!',
        body: 'Reason: $reason',
      );
    } catch (e) {
      throw 'Error sending Bak: ${e.toString()}';
    }
  }

  // Method to request a consumed 'Bak'
  static Future<void> requestConsumedBak({
    required String associationId,
    required int amount,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      // Insert consumed 'Bak' request
      await supabase.from('bak_consumed').insert({
        'taker_id': userId,
        'association_id': associationId,
        'amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Error requesting consumed Bak: ${e.toString()}';
    }
  }

  // Method to create a bet
  static Future<void> createBet({
    required String receiverId,
    required String associationId,
    required int amount,
    required String description,
  }) async {
    final supabase = Supabase.instance.client;
    final creatorId = supabase.auth.currentUser!.id;

    try {
      // Insert the bet into the 'bets' table
      await supabase.from('bets').insert({
        'bet_creator_id': creatorId,
        'bet_receiver_id': receiverId,
        'association_id': associationId,
        'amount': amount,
        'bet_description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Fetch the creator's name for the notification
      final creatorResponse = await supabase
          .from('users')
          .select('name')
          .eq('id', creatorId)
          .single();
      final creatorName = creatorResponse['name'];

      // Notify the receiver about the bet
      await _insertNotification(
        userId: receiverId,
        title: 'New Bet from $creatorName',
        body: 'Amount: $amount Bakken. Description: $description.',
      );
    } catch (e) {
      throw 'Error creating bet: ${e.toString()}';
    }
  }

  // Method to update the status of a bet (Accept/Reject)
  static Future<void> updateBetStatus({
    required String betId,
    required String receiverId,
    required String newStatus,
    required String creatorId,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    // Ensure only the receiver can accept or reject the bet
    if (userId != receiverId) {
      throw 'Only the receiver can accept or reject the bet.';
    }

    try {
      // Update the bet's status
      await supabase.from('bets').update({'status': newStatus}).eq('id', betId);

      // Notify the creator about the bet's status change
      final notificationMessage = newStatus == 'accepted'
          ? 'Your bet has been accepted!'
          : 'Your bet has been rejected.';

      await _insertNotification(
        userId: creatorId,
        title: 'Bet $newStatus',
        body: notificationMessage,
      );
    } catch (e) {
      throw 'Error updating bet status: ${e.toString()}';
    }
  }

  // Method to settle the bet
  static Future<void> settleBet({
    required String betId,
    required String winnerId,
    required String loserId,
    required int amount,
    required String associationId,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      // Step 1: Update the bet's status to 'settled' and assign the winner
      await supabase.from('bets').update({
        'status': 'settled',
        'winner_id': winnerId,
      }).eq('id', betId);

      // Step 2: Update the loser's baks_received count
      final loserResponse = await supabase
          .from('association_members')
          .select('baks_received')
          .eq('user_id', loserId)
          .eq('association_id', associationId)
          .single();

      final updatedBaksReceived = loserResponse['baks_received'] + amount;
      await supabase
          .from('association_members')
          .update({'baks_received': updatedBaksReceived})
          .eq('user_id', loserId)
          .eq('association_id', associationId);

      // Step 3: Notify both winner and loser about the outcome
      await _insertNotification(
        userId: winnerId,
        title: 'Congratulations!',
        body: 'You have won the bet and received $amount Bakken.',
      );

      await _insertNotification(
        userId: loserId,
        title: 'Better luck next time!',
        body: 'You lost the bet and owe $amount Bakken.',
      );
    } catch (e) {
      throw 'Error settling bet: ${e.toString()}';
    }
  }

  // Helper method to insert notifications
  static Future<void> _insertNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Error sending notification: ${e.toString()}';
    }
  }
}
