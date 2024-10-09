import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/services/home_widget_service.dart';
import 'package:bak_tracker/services/local_storage_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'association_event.dart';
import 'association_state.dart';

class AssociationBloc extends Bloc<AssociationEvent, AssociationState> {
  final AssociationService _associationService;
  final LocalStorageService _localStorageService;

  AssociationBloc(this._associationService)
      : _localStorageService = LocalStorageService(),
        super(AssociationInitial()) {
    on<SelectAssociation>(_onSelectAssociation);
    on<LeaveAssociation>(_onLeaveAssociation);
    on<ClearAssociationError>(_onClearAssociationError);
    on<RefreshPendingApproveBaks>(_onRefreshPendingBaks);
    on<RefreshBaksAndBets>(_onRefreshBaksAndBets);
    on<JoinNewAssociation>(_onJoinNewAssociation);
    on<RefreshMemberAchievements>(_onRefreshMemberAchievements);
    on<UpdateMemberRole>(_onUpdateMemberRole);
    on<UpdateMemberStats>(_onUpdateMemberStats);

    _initialize();
  }

  // Initialize shared preferences and load selected association
  void _initialize() async {
    await _loadSelectedAssociation();
  }

  Future<void> _loadSelectedAssociation() async {
    final savedAssociation =
        await _localStorageService.loadSelectedAssociation();
    if (savedAssociation != null) {
      add(SelectAssociation(selectedAssociation: savedAssociation));
    }
  }

  Future<void> _saveSelectedAssociation(AssociationModel association) async {
    await _localStorageService.saveSelectedAssociation(association);
  }

  Future<void> _onSelectAssociation(
      SelectAssociation event, Emitter<AssociationState> emit) async {
    emit(const AssociationLoading());

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      emit(const AssociationError('User not authenticated'));
      return;
    }

    _saveSelectedAssociation(event.selectedAssociation);

    try {
      final responses = await Future.wait([
        _fetchMemberData(event.selectedAssociation.id, userId),
        _associationService.fetchMembers(event.selectedAssociation.id),
        _associationService.fetchPendingBaksCount(
            event.selectedAssociation.id, userId),
        _associationService
            .fetchPendingApproveBaksCount(event.selectedAssociation.id),
        _associationService.fetchPendingBetsCount(
            event.selectedAssociation.id, userId),
      ]);

      final memberData = responses[0] as AssociationMemberModel;
      final members = responses[1] as List<AssociationMemberModel>;
      final pendingBaksCount = responses[2] as int;
      final pendingApproveBaksCount = responses[3] as int;
      final pendingBetsCount = responses[4] as int;

      await WidgetService.updateDrinkInfo(
        event.selectedAssociation.name,
        memberData.baksConsumed.toString(),
        memberData.baksReceived.toString(),
        memberData.betsWon.toString(),
        memberData.betsLost.toString(),
      );

      emit(AssociationLoaded(
        selectedAssociation: event.selectedAssociation,
        memberData: memberData,
        members: members,
        pendingBaksCount: pendingBaksCount,
        pendingBetsCount: pendingBetsCount,
        pendingApproveBaksCount: pendingApproveBaksCount,
      ));
    } catch (e) {
      emit(AssociationError('Failed to select association: ${e.toString()}'));
    }
  }

  Future<AssociationMemberModel> _fetchMemberData(
      String associationId, String userId) async {
    final response = await Supabase.instance.client
        .from('association_members')
        .select(
            'id, user_id (id, name, profile_image, bio, fcm_token), association_id, role, permissions, joined_at, baks_received, baks_consumed, bets_won, bets_lost, member_achievements (id, assigned_at, achievement_id(id, name, association_id, description, created_at))')
        .eq('user_id', userId)
        .eq('association_id', associationId)
        .single();
    return AssociationMemberModel.fromMap(response);
  }

  Future<void> _onJoinNewAssociation(
      JoinNewAssociation event, Emitter<AssociationState> emit) async {
    emit(const AssociationLoading());
    try {
      await _saveSelectedAssociation(event.newAssociation);
      emit(const AssociationJoined());
    } catch (e) {
      emit(AssociationError('Failed to join association: ${e.toString()}'));
    }
  }

  Future<void> _onLeaveAssociation(
      LeaveAssociation event, Emitter<AssociationState> emit) async {
    final currentState = state;
    emit(const AssociationLoading());

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _emitLeaveError(emit, currentState, 'User not authenticated');
      return;
    }

    try {
      final currentUser = await _fetchMemberData(event.associationId, userId);
      if (currentUser.permissions
          .hasPermission(PermissionEnum.hasAllPermissions)) {
        final otherAdmins =
            await _fetchOtherAdmins(event.associationId, userId);
        if (otherAdmins.isEmpty) {
          _emitLeaveError(emit, currentState,
              'You cannot leave the association as you are the only member with Full permissions.');
          return;
        }
      }

      await Supabase.instance.client
          .from('association_members')
          .delete()
          .eq('user_id', userId)
          .eq('association_id', event.associationId);

      final remainingAssociations = await _fetchRemainingAssociations(userId);
      await _localStorageService.removeSelectedAssociation();
      await WidgetService.resetWidget();

      if (remainingAssociations.isEmpty) {
        emit(const NoAssociationsLeft());
      } else {
        emit(const AssociationLeft());
      }
    } catch (e) {
      _emitLeaveError(
          emit, currentState, 'Failed to leave association: ${e.toString()}');
    }
  }

  Future<List<dynamic>> _fetchOtherAdmins(
      String associationId, String userId) async {
    return Supabase.instance.client
        .from('association_members')
        .select('user_id, permissions')
        .eq('association_id', associationId)
        .neq('user_id', userId)
        .containedBy('permissions', {'hasAllPermissions': true});
  }

  Future<List<dynamic>> _fetchRemainingAssociations(String userId) async {
    return Supabase.instance.client
        .from('association_members')
        .select('association_id')
        .eq('user_id', userId);
  }

  void _emitLeaveError(Emitter<AssociationState> emit,
      AssociationState currentState, String message) {
    if (currentState is AssociationLoaded) {
      emit(currentState.copyWith(errorMessage: message));
    } else {
      emit(AssociationError(message));
    }
  }

  Future<void> _onRefreshPendingBaks(
      RefreshPendingApproveBaks event, Emitter<AssociationState> emit) async {
    if (state is AssociationLoaded) {
      try {
        final pendingApproveBaksCount = await _associationService
            .fetchPendingApproveBaksCount(event.associationId);
        emit((state as AssociationLoaded)
            .copyWith(pendingApproveBaksCount: pendingApproveBaksCount));
      } catch (e) {
        emit(AssociationError('Failed to refresh pending approve baks: $e'));
      }
    }
  }

  Future<void> _onRefreshBaksAndBets(
      RefreshBaksAndBets event, Emitter<AssociationState> emit) async {
    if (state is AssociationLoaded) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const AssociationError('User not authenticated'));
        return;
      }

      try {
        final pendingBaksCount = await _associationService
            .fetchPendingBaksCount(event.associationId, userId);
        final pendingBetsCount = await _associationService
            .fetchPendingBetsCount(event.associationId, userId);

        emit((state as AssociationLoaded).copyWith(
          pendingBaksCount: pendingBaksCount,
          pendingBetsCount: pendingBetsCount,
        ));
      } catch (e) {
        emit(AssociationError('Failed to refresh baks and bets: $e'));
      }
    }
  }

  Future<void> _onRefreshMemberAchievements(
      RefreshMemberAchievements event, Emitter<AssociationState> emit) async {
    if (state is AssociationLoaded) {
      final currentState = state as AssociationLoaded;

      try {
        final member =
            currentState.members.firstWhere((m) => m.id == event.memberId);
        final updatedAchievements =
            await _associationService.fetchMemberAchievements(event.memberId);

        final updatedMember =
            member.copyWith(achievements: updatedAchievements);
        final updatedMembers = currentState.members
            .map((m) => m.id == updatedMember.id ? updatedMember : m)
            .toList();

        emit(currentState.copyWith(members: updatedMembers));
      } catch (e) {
        emit(AssociationError(
            'Failed to refresh achievements: ${e.toString()}'));
      }
    }
  }

  Future<void> _onUpdateMemberRole(
      UpdateMemberRole event, Emitter<AssociationState> emit) async {
    if (state is AssociationLoaded) {
      final currentState = state as AssociationLoaded;

      try {
        // Update the role in the database
        await _associationService.updateMemberRole(
            event.associationId, event.memberId, event.newRole);

        // Find and update the specific member's role in the state
        final updatedMembers = currentState.members.map((member) {
          if (member.user.id == event.memberId) {
            return member.copyWith(role: event.newRole);
          }
          return member;
        }).toList();

        // Emit the updated state
        emit(currentState.copyWith(members: updatedMembers));
      } catch (e) {
        emit(AssociationError('Failed to update role: ${e.toString()}'));
      }
    }
  }

  // Handler for updating member stats
  Future<void> _onUpdateMemberStats(
      UpdateMemberStats event, Emitter<AssociationState> emit) async {
    if (state is AssociationLoaded) {
      final currentState = state as AssociationLoaded;

      try {
        // Update the stats in the database
        await _associationService.updateMemberStats(
          event.associationId,
          event.memberId,
          event.baksConsumed,
          event.baksReceived,
          event.betsWon,
          event.betsLost,
        );

        // Find and update the specific member's stats in the state
        final updatedMembers = currentState.members.map((member) {
          if (member.user.id == event.memberId) {
            return member.copyWith(
              baksConsumed: event.baksConsumed,
              baksReceived: event.baksReceived,
              betsWon: event.betsWon,
              betsLost: event.betsLost,
            );
          }
          return member;
        }).toList();

        // Emit the updated state
        emit(currentState.copyWith(members: updatedMembers));
      } catch (e) {
        emit(AssociationError('Failed to update stats: ${e.toString()}'));
      }
    }
  }

  void _onClearAssociationError(
      ClearAssociationError event, Emitter<AssociationState> emit) {
    if (state is AssociationLoaded) {
      emit((state as AssociationLoaded).copyWith(errorMessage: null));
    } else {
      emit(const AssociationError('No error to clear.'));
    }
  }
}
