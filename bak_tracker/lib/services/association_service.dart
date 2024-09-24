import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/association_member_model.dart';

class AssociationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AssociationMemberModel>> fetchMembers(
      String associationId) async {
    final List<dynamic> response = await _supabase
        .from('association_members')
        .select(
            'user_id (id, name, profile_image_path), association_id, role, permissions, joined_at, baks_received, baks_consumed')
        .eq('association_id', associationId);

    return response.map((data) {
      final userMap = data['user_id'] as Map<String, dynamic>;
      return AssociationMemberModel(
        userId: userMap['id'],
        name: userMap['name'],
        profileImagePath: userMap['profile_image_path'],
        associationId: data['association_id'],
        role: data['role'],
        permissions: data['permissions'] is String
            ? jsonDecode(data['permissions']) as Map<String, dynamic>
            : data['permissions'] as Map<String, dynamic>,
        joinedAt: DateTime.parse(data['joined_at']),
        baksReceived: data['baks_received'],
        baksConsumed: data['baks_consumed'],
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

  Future<void> resetAllBaks(String associationId) async {
    try {
      // Reset baks_received and baks_consumed for all members of the association
      final response = await _supabase
          .from('association_members')
          .update({'baks_received': 0, 'baks_consumed': 0}).eq(
              'association_id', associationId);

      if (response == null || response.error != null) {
        throw Exception('Failed to reset BAKs');
      }
    } catch (e) {
      throw Exception('Error resetting BAKs: ${e.toString()}');
    }
  }
}
