import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';

class JoinAssociationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AssociationModel> joinAssociation(String inviteCode) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw 'User not authenticated.';
    }

    try {
      // Fetch the invite details, including permissions
      final inviteResponse = await _supabase
          .from('invites')
          .select('association_id, permissions')
          .eq('invite_key', inviteCode)
          .eq('is_expired', false)
          .maybeSingle();

      if (inviteResponse == null) {
        throw 'Invalid or expired invite code.';
      }

      final associationId = inviteResponse['association_id'];
      final invitePermissions = inviteResponse['permissions'];

      // Check if the user is already a member of the association
      final isMember = await _supabase
          .from('association_members')
          .select('id')
          .eq('association_id', associationId)
          .eq('user_id', userId)
          .maybeSingle();

      if (isMember != null) {
        throw 'You are already a member of this association.';
      }

      // Insert the new member with the permissions from the invite
      await _supabase.from('association_members').insert({
        'user_id': userId,
        'association_id': associationId,
        'role': 'member',
        'permissions': invitePermissions,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Fetch and return the associated association details
      final associationResponse = await _supabase
          .from('associations')
          .select()
          .eq('id', associationId)
          .single();

      return AssociationModel.fromMap(associationResponse);
    } catch (e) {
      throw 'Error joining association: $e';
    }
  }
}
