import 'package:bak_tracker/models/association_member_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PermissionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AssociationMemberModel?> fetchMemberPermissions(String userId) async {
    try {
      final response = await _client
          .from('association_members')
          .select()
          .eq('user_id', userId)
          .single();

      return AssociationMemberModel.fromMap(response);
    } catch (e) {
      print('Exception occurred: $e');
      return null;
    }
  }
}
