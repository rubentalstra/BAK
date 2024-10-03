import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/models/achievement_model.dart';
import 'package:bak_tracker/models/member_achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/association_member_model.dart';

class AssociationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches members for a given association ID and their achievements
  Future<List<AssociationMemberModel>> fetchMembers(
      String associationId) async {
    final List<dynamic> response = await _supabase
        .from('association_members')
        .select('''
            id, 
            user_id (id, name, profile_image, bio, fcm_token), 
            association_id, 
            role, 
            permissions, 
            joined_at, 
            baks_received, 
            baks_consumed, 
            bets_won, 
            bets_lost,
            member_achievements (id, assigned_at, achievement_id(id, name, description, created_at))
        ''')
        .eq('association_id', associationId)
        .order('user_id(name)', ascending: true);

    return List<AssociationMemberModel>.from(
      response.map((data) {
        return AssociationMemberModel.fromMap(data);
      }),
    );
  }

  Future<int> fetchPendingBaksCount(String associationId, String userId) async {
    final response = await _supabase
        .from('bak_send')
        .select()
        .eq('association_id', associationId)
        .eq('receiver_id', userId)
        .eq('status', 'pending');
    return response.length;
  }

  Future<int> fetchPendingAproveBaksCount(String associationId) async {
    final response = await _supabase
        .from('bak_consumed')
        .select()
        .eq('association_id', associationId)
        .eq('status', 'pending');
    return response.length;
  }

  Future<int> fetchPendingBetsCount(String associationId, String userId) async {
    final response = await _supabase
        .from('bets')
        .select()
        .eq('association_id', associationId)
        .or('bet_creator_id.eq.$userId,bet_receiver_id.eq.$userId')
        .inFilter('status', ['pending', 'accepted']);
    return response.length;
  }

  Future<AssociationModel> fetchAssociationById(String associationId) async {
    final Map<String, dynamic> response = await _supabase
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

  // Achievement methods
  Future<List<AchievementModel>> fetchAchievements(String associationId) async {
    final response = await _supabase
        .from('achievements')
        .select()
        .eq('association_id', associationId)
        .order('created_at', ascending: false);

    if (response.isNotEmpty) {
      return response
          .map<AchievementModel>(
              (achievement) => AchievementModel.fromMap(achievement))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> createAchievement(
      String associationId, String name, String? description) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('achievements').insert({
      'association_id': associationId,
      'created_by': userId,
      'name': name,
      'description': description,
    });
  }

  Future<void> updateAchievement(
      String achievementId, String name, String? description) async {
    await _supabase.from('achievements').update(
        {'name': name, 'description': description}).eq('id', achievementId);
  }

  Future<void> deleteAchievement(String achievementId) async {
    await _supabase.from('achievements').delete().eq('id', achievementId);
  }

  // Fetches achievements assigned to a specific member
  Future<List<MemberAchievementModel>> fetchMemberAchievements(
      String memberId) async {
    final response = await _supabase
        .from('member_achievements')
        .select(
            'achievement_id(id, name, description, created_at), assigned_at')
        .eq('member_id', memberId);

    if (response.isNotEmpty) {
      return response.map<MemberAchievementModel>((data) {
        return MemberAchievementModel.fromMap(data);
      }).toList();
    } else {
      return [];
    }
  }

  Future<void> assignAchievements(
      String memberId, List<String> achievementIds) async {
    await _supabase.from('member_achievements').insert(achievementIds.map((id) {
          return {'member_id': memberId, 'achievement_id': id};
        }).toList());
  }

  Future<void> removeAchievement(String memberId, String achievementId) async {
    await _supabase
        .from('member_achievements')
        .delete()
        .eq('member_id', memberId)
        .eq('achievement_id', achievementId);
  }

  Future<void> updateMemberAchievements(
      String memberId, List<String> achievementIds) async {
    // Fetch current achievements of the member
    final currentAchievements = await fetchMemberAchievements(memberId);

    // Extract current achievement IDs
    final currentAchievementIds =
        currentAchievements.map((a) => a.achievement.id).toList();

    // Determine which achievements to add and which to remove
    final achievementsToAdd = achievementIds
        .where((id) => !currentAchievementIds.contains(id))
        .toList();
    final achievementsToRemove = currentAchievementIds
        .where((id) => !achievementIds.contains(id))
        .toList();

    // Add new achievements
    if (achievementsToAdd.isNotEmpty) {
      await assignAchievements(memberId, achievementsToAdd);
    }

    // Remove unassigned achievements
    if (achievementsToRemove.isNotEmpty) {
      for (var achievementId in achievementsToRemove) {
        await removeAchievement(memberId, achievementId);
      }
    }
  }

  // Method to update permissions for a member
  Future<void> updateMemberPermissions(
      String memberId, PermissionsModel permissions) async {
    await _supabase
        .from('association_members')
        .update({'permissions': permissions.toMap()}).eq('user_id', memberId);
  }

  Future<void> updateBakRegulations(
      String associationId, String? newFileName) async {
    await _supabase.from('associations').update({
      'bak_regulations': newFileName,
    }).eq('id', associationId);
  }
}
