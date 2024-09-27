import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/association_member_model.dart';

class AssociationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches members for a given association ID
  Future<List<AssociationMemberModel>> fetchMembers(
      String associationId) async {
    final List<dynamic> response = await _supabase
        .from('association_members')
        .select(
            'user_id (id, name, profile_image, bio), association_id, role, permissions, joined_at, baks_received, baks_consumed, bets_won, bets_lost')
        .eq('association_id', associationId);

    return response.map((data) {
      final userMap = data['user_id'] as Map<String, dynamic>;
      return AssociationMemberModel(
        userId: userMap['id'],
        name: userMap['name'],
        bio: userMap['bio'],
        profileImage: userMap['profile_image'],
        associationId: data['association_id'],
        role: data['role'],
        permissions: data['permissions'] is String
            ? jsonDecode(data['permissions']) as Map<String, dynamic>
            : data['permissions'] as Map<String, dynamic>,
        joinedAt: DateTime.parse(data['joined_at']),
        baksReceived: data['baks_received'],
        baksConsumed: data['baks_consumed'],
        betsWon: data['bets_won'],
        betsLost: data['bets_lost'],
      );
    }).toList();
  }

  Future<int> fetchPendingBaksCount(String associationId) async {
    final pendingBaksResponse = await _supabase
        .from('bak_consumed')
        .select('status')
        .eq('association_id', associationId)
        .eq('status', 'pending');

    return pendingBaksResponse.length;
  }

  Future<AssociationModel> fetchAssociationById(String associationId) async {
    final response = await _supabase
        .from('associations')
        .select()
        .eq('id', associationId)
        .single();

    return AssociationModel.fromMap(response);
  }

  Future<String> resetAllStats(String associationId) async {
    try {
      await _supabase.from('association_members').update({
        'baks_received': 0,
        'baks_consumed': 0,
        'bets_won': 0,
        'bets_lost': 0
      }).eq('association_id', associationId);

      return 'BAKs reset successfully';
    } catch (e) {
      return 'Error resetting BAKs: ${e.toString()}';
    }
  }
}
