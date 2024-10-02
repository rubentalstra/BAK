import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';

class JoinAssociationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AssociationModel> joinAssociation(String inviteCode) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw UserNotAuthenticatedException();
    }

    final inviteDetails = await _fetchInviteDetails(inviteCode);
    if (inviteDetails == null) {
      throw InvalidInviteCodeException();
    }

    final associationId = inviteDetails['association_id'];
    final invitePermissions = inviteDetails['permissions'];

    await _checkMembership(associationId, userId);

    await _addMemberToAssociation(userId, associationId, invitePermissions);

    return await _fetchAssociationDetails(associationId);
  }

  Future<Map<String, dynamic>?> _fetchInviteDetails(String inviteCode) async {
    return await _supabase
        .from('invites')
        .select('association_id, permissions')
        .eq('invite_key', inviteCode)
        .eq('is_expired', false)
        .maybeSingle();
  }

  Future<void> _checkMembership(String associationId, String userId) async {
    final isMember = await _supabase
        .from('association_members')
        .select('id')
        .eq('association_id', associationId)
        .eq('user_id', userId)
        .maybeSingle();

    if (isMember != null) {
      throw AlreadyAMemberException();
    }
  }

  Future<void> _addMemberToAssociation(String userId, String associationId,
      Map<String, dynamic> invitePermissions) async {
    await _supabase.from('association_members').insert({
      'user_id': userId,
      'association_id': associationId,
      'role': 'member',
      'permissions': invitePermissions,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<AssociationModel> _fetchAssociationDetails(
      String associationId) async {
    final associationResponse = await _supabase
        .from('associations')
        .select()
        .eq('id', associationId)
        .single();

    return AssociationModel.fromMap(associationResponse);
  }
}

// Custom Exceptions
class UserNotAuthenticatedException implements Exception {
  @override
  String toString() => 'User is not authenticated.';
}

class InvalidInviteCodeException implements Exception {
  @override
  String toString() => 'Invalid or expired invite code.';
}

class AlreadyAMemberException implements Exception {
  @override
  String toString() => 'You are already a member of this association.';
}
