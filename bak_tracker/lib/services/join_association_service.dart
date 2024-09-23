import 'package:supabase_flutter/supabase_flutter.dart';

class JoinAssociationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Method to join the association using an invite code
  Future<String?> joinAssociation(String inviteCode) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return 'User not authenticated.';
    }

    try {
      // Check if the invite code is valid, not expired, and retrieve association id
      final inviteResponse = await _supabase
          .from('invites')
          .select('association_id')
          .eq('invite_key', inviteCode)
          .eq('is_expired', false)
          .maybeSingle();

      if (inviteResponse == null) {
        return 'Invalid or expired invite code.';
      }

      final associationId = inviteResponse['association_id'];

      // Check if the user is already a member of the association
      final isMember = await _supabase
          .from('association_members')
          .select('id')
          .eq('association_id', associationId)
          .eq('user_id', userId)
          .maybeSingle();

      if (isMember != null) {
        return 'You are already a member of this association.';
      }

      // Add the user to the association
      await _supabase.from('association_members').insert({
        'user_id': userId,
        'association_id': associationId,
        'role': 'member', // Default role, can be adjusted
        'permissions': {}, // Default permissions
        'joined_at': DateTime.now().toIso8601String(),
      });

      return null; // Success, no error
    } catch (e) {
      return 'Error joining association: $e';
    }
  }
}
