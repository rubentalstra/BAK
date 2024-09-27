import 'package:supabase_flutter/supabase_flutter.dart';

class BakService {
  static Future<void> sendBak({
    required String receiverId,
    required String associationId,
    required int amount,
    required String reason,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      final userResponse =
          await supabase.from('users').select('name').eq('id', userId).single();
      final giverName = userResponse['name'];

      await supabase.from('bak_send').insert({
        'giver_id': userId,
        'receiver_id': receiverId,
        'association_id': associationId,
        'amount': amount,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _insertNotification(
        receiverId: receiverId,
        giverName: giverName,
        reason: reason,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> _insertNotification({
    required String receiverId,
    required String giverName,
    required String reason,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('notifications').insert({
        'user_id': receiverId,
        'title': 'You received a Bak from $giverName!',
        'body': 'Reason: $reason',
      });
    } catch (e) {
      throw e.toString();
    }
  }
}
