import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/models/achievement_model.dart';
import 'package:bak_tracker/models/member_achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/association_member_model.dart';

class AssociationService {
  final SupabaseClient _supabase;

  // Constructor to initialize the Supabase client
  AssociationService(this._supabase);

  // Fetches members for a given association ID and their achievements
  Future<List<AssociationMemberModel>> fetchMembers(
      String associationId) async {
    try {
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

      return response
          .map<AssociationMemberModel>(
              (data) => AssociationMemberModel.fromMap(data))
          .toList();
    } catch (e) {
      _handleError('fetchMembers', e);
      return [];
    }
  }

  // Fetches drink stats (baks consumed and received) for a specific user and association
  Future<Map<String, int>> fetchDrinkStats(
      String associationId, String userId) async {
    try {
      final response = await _supabase
          .from('association_members')
          .select('baks_consumed, baks_received')
          .eq('user_id', userId)
          .eq('association_id', associationId)
          .single();

      return {
        'chuckedDrinks': response['baks_consumed'] ?? 0,
        'drinkDebt': response['baks_received'] ?? 0,
      };
    } catch (e) {
      _handleError('fetchDrinkStats', e);
      return {'chuckedDrinks': 0, 'drinkDebt': 0};
    }
  }

  // Fetches pending baks count for a specific user and association
  Future<int> fetchPendingBaksCount(String associationId, String userId) async {
    try {
      final response = await _supabase
          .from('bak_send')
          .select()
          .eq('association_id', associationId)
          .eq('receiver_id', userId)
          .eq('status', 'pending');
      return response.length;
    } catch (e) {
      _handleError('fetchPendingBaksCount', e);
      return 0;
    }
  }

  // Fetches pending approval baks count for an association
  Future<int> fetchPendingApproveBaksCount(String associationId) async {
    try {
      final response = await _supabase
          .from('bak_consumed')
          .select()
          .eq('association_id', associationId)
          .eq('status', 'pending');
      return response.length;
    } catch (e) {
      _handleError('fetchPendingApproveBaksCount', e);
      return 0;
    }
  }

  // Fetches pending bets count for a specific user and association
  Future<int> fetchPendingBetsCount(String associationId, String userId) async {
    try {
      final response = await _supabase
          .from('bets')
          .select()
          .eq('association_id', associationId)
          .or('bet_creator_id.eq.$userId,bet_receiver_id.eq.$userId')
          .inFilter('status', ['pending', 'accepted']);
      return response.length;
    } catch (e) {
      _handleError('fetchPendingBetsCount', e);
      return 0;
    }
  }

  // Fetches a specific association by ID
  Future<AssociationModel?> fetchAssociationById(String associationId) async {
    try {
      final response = await _supabase
          .from('associations')
          .select()
          .eq('id', associationId)
          .single();

      return AssociationModel.fromMap(response);
    } catch (e) {
      _handleError('fetchAssociationById', e);
      return null;
    }
  }

  // Resets all stats (baks received, consumed, bets won, bets lost) for an association
  Future<String> resetAllStats(String associationId) async {
    try {
      await _supabase.from('association_members').update({
        'baks_received': 0,
        'baks_consumed': 0,
        'bets_won': 0,
        'bets_lost': 0,
      }).eq('association_id', associationId);

      return 'BAKs reset successfully';
    } catch (e) {
      _handleError('resetAllStats', e);
      return 'Error resetting BAKs';
    }
  }

  // Updates stats (baks consumed, baks received, bets won, bets lost) for a specific member
  Future<void> updateMemberStats(String associationId, String memberId,
      int baksConsumed, int baksReceived, int betsWon, int betsLost) async {
    try {
      await _supabase
          .from('association_members')
          .update({
            'baks_consumed': baksConsumed,
            'baks_received': baksReceived,
            'bets_won': betsWon,
            'bets_lost': betsLost,
          })
          .eq('association_id', associationId)
          .eq('user_id', memberId);
    } catch (e) {
      _handleError('updateMemberStats', e);
    }
  }

  // Fetches achievements for a given association
  Future<List<AchievementModel>> fetchAchievements(String associationId) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('association_id', associationId)
          .order('created_at', ascending: false);

      return response.isNotEmpty
          ? response
              .map<AchievementModel>((data) => AchievementModel.fromMap(data))
              .toList()
          : [];
    } catch (e) {
      _handleError('fetchAchievements', e);
      return [];
    }
  }

  // Creates a new achievement
  Future<void> createAchievement(
      String associationId, String name, String? description) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      await _supabase.from('achievements').insert({
        'association_id': associationId,
        'created_by': userId,
        'name': name,
        'description': description,
      });
    } catch (e) {
      _handleError('createAchievement', e);
    }
  }

  // Updates an existing achievement
  Future<void> updateAchievement(
      String achievementId, String name, String? description) async {
    try {
      await _supabase.from('achievements').update(
          {'name': name, 'description': description}).eq('id', achievementId);
    } catch (e) {
      _handleError('updateAchievement', e);
    }
  }

  // Deletes an achievement
  Future<void> deleteAchievement(String achievementId) async {
    try {
      await _supabase.from('achievements').delete().eq('id', achievementId);
    } catch (e) {
      _handleError('deleteAchievement', e);
    }
  }

  // Fetches member achievements
  Future<List<MemberAchievementModel>> fetchMemberAchievements(
      String memberId) async {
    try {
      final response = await _supabase
          .from('member_achievements')
          .select(
              'achievement_id(id, name, description, created_at), assigned_at')
          .eq('member_id', memberId);

      return response.isNotEmpty
          ? response
              .map<MemberAchievementModel>(
                  (data) => MemberAchievementModel.fromMap(data))
              .toList()
          : [];
    } catch (e) {
      _handleError('fetchMemberAchievements', e);
      return [];
    }
  }

  // Assigns achievements to a member
  Future<void> assignAchievements(
      String memberId, List<String> achievementIds) async {
    try {
      await _supabase
          .from('member_achievements')
          .insert(achievementIds.map((id) {
            return {'member_id': memberId, 'achievement_id': id};
          }).toList());
    } catch (e) {
      _handleError('assignAchievements', e);
    }
  }

  // Removes a specific achievement from a member
  Future<void> removeAchievement(String memberId, String achievementId) async {
    try {
      await _supabase
          .from('member_achievements')
          .delete()
          .eq('member_id', memberId)
          .eq('achievement_id', achievementId);
    } catch (e) {
      _handleError('removeAchievement', e);
    }
  }

  // Updates the achievements of a member
  Future<void> updateMemberAchievements(
      String memberId, List<String> achievementIds) async {
    final currentAchievements = await fetchMemberAchievements(memberId);
    final currentAchievementIds =
        currentAchievements.map((a) => a.achievement.id).toList();

    final achievementsToAdd = achievementIds
        .where((id) => !currentAchievementIds.contains(id))
        .toList();
    final achievementsToRemove = currentAchievementIds
        .where((id) => !achievementIds.contains(id))
        .toList();

    try {
      if (achievementsToAdd.isNotEmpty) {
        await assignAchievements(memberId, achievementsToAdd);
      }
      if (achievementsToRemove.isNotEmpty) {
        for (var achievementId in achievementsToRemove) {
          await removeAchievement(memberId, achievementId);
        }
      }
    } catch (e) {
      _handleError('updateMemberAchievements', e);
    }
  }

  // Updates member permissions
  Future<void> updateMemberPermissions(
      String memberId, PermissionsModel permissions) async {
    try {
      await _supabase
          .from('association_members')
          .update({'permissions': permissions.toMap()}).eq('user_id', memberId);
    } catch (e) {
      _handleError('updateMemberPermissions', e);
    }
  }

  // Updates Bak regulations for an association
  Future<void> updateBakRegulations(
      String associationId, String? newFileName) async {
    try {
      await _supabase
          .from('associations')
          .update({'bak_regulations': newFileName}).eq('id', associationId);
    } catch (e) {
      _handleError('updateBakRegulations', e);
    }
  }

  // Updates the role for a specific user in a given association
  Future<void> updateMemberRole(
      String associationId, String userId, String newRole) async {
    try {
      await _supabase
          .from('association_members')
          .update({'role': newRole})
          .eq('user_id', userId)
          .eq('association_id', associationId);
    } catch (e) {
      _handleError('updateMemberRole', e);
    }
  }

  // Centralized error handling
  void _handleError(String methodName, Object e) {
    print('Error in $methodName: $e');
    throw 'Error in $methodName: ${e.toString()}';
  }
}
