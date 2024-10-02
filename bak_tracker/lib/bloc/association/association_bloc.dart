import 'dart:convert';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'association_event.dart';
import 'association_state.dart';

class AssociationBloc extends Bloc<AssociationEvent, AssociationState> {
  final AssociationService _associationService = AssociationService();
  SharedPreferences? _prefs;

  AssociationBloc() : super(AssociationInitial()) {
    on<SelectAssociation>(_onSelectAssociation);
    on<LeaveAssociation>(_onLeaveAssociation);
    on<ClearAssociationError>(_onClearAssociationError);
    on<RefreshPendingAproveBaks>(_onRefreshPendingBaks);
    on<RefreshBaksAndBets>(_onRefreshBaksAndBets);
    on<JoinNewAssociation>(_onJoinNewAssociation);
    _loadSelectedAssociation();
  }

  Future<void> _loadSelectedAssociation() async {
    _prefs ??= await SharedPreferences.getInstance();
    final String? selectedAssociationData =
        _prefs?.getString('selected_association');

    if (selectedAssociationData != null) {
      final associationMap =
          jsonDecode(selectedAssociationData) as Map<String, dynamic>;
      final selectedAssociation = AssociationModel.fromMap(associationMap);
      add(SelectAssociation(selectedAssociation: selectedAssociation));
    }
  }

  Future<void> _saveSelectedAssociation(AssociationModel association) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!
        .setString('selected_association', jsonEncode(association.toMap()));
  }

  Future<void> _onSelectAssociation(
      SelectAssociation event, Emitter<AssociationState> emit) async {
    emit(AssociationLoading());

    try {
      await _saveSelectedAssociation(event.selectedAssociation);

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        emit(AssociationError('User not authenticated'));
        return;
      }

      // Fetch member data first
      final memberResponse = await supabase
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
          member_achievements (id, assigned_at, achievement_id(id, name, association_id, description, created_at))
        ''')
          .eq('user_id', userId)
          .eq('association_id', event.selectedAssociation.id)
          .single();

      if (memberResponse.isEmpty) {
        emit(AssociationError('Failed to load association member data.'));
        return;
      }

      // Fetch member data, members list, pending baks, pending approve baks, and pending bets concurrently
      final List<dynamic> futures = await Future.wait([
        _fetchMembers(event.selectedAssociation.id),
        _fetchPendingBaksCount(event.selectedAssociation.id, userId),
        _fetchPendingAproveBaksCount(event.selectedAssociation.id),
        _fetchPendingBetsCount(event.selectedAssociation.id, userId),
      ]);

      final List<AssociationMemberModel> members = futures[0];
      final int pendingBaksCount = futures[1];
      final int pendingAproveBaksCount = futures[2];
      final int pendingBetsCount = futures[3];

      final memberData = AssociationMemberModel.fromMap(memberResponse);

      emit(AssociationLoaded(
        selectedAssociation: event.selectedAssociation,
        memberData: memberData,
        members: members,
        pendingBaksCount: pendingBaksCount,
        pendingBetsCount: pendingBetsCount,
        pendingAproveBaksCount: pendingAproveBaksCount,
      ));
    } catch (e) {
      emit(AssociationError('Failed to select association: ${e.toString()}'));
    }
  }

// Fetch members with error handling
  Future<List<AssociationMemberModel>> _fetchMembers(
      String associationId) async {
    try {
      return await _associationService.fetchMembers(associationId);
    } catch (e) {
      throw Exception('Failed to fetch members: $e');
    }
  }

// Fetch pending baks count with error handling
  Future<int> _fetchPendingBaksCount(
      String associationId, String userId) async {
    try {
      return await _associationService.fetchPendingBaksCount(
          associationId, userId);
    } catch (e) {
      throw Exception('Failed to fetch pending baks count: $e');
    }
  }

// Fetch pending approve baks count with error handling
  Future<int> _fetchPendingAproveBaksCount(String associationId) async {
    try {
      return await _associationService
          .fetchPendingAproveBaksCount(associationId);
    } catch (e) {
      throw Exception('Failed to fetch pending approve baks count: $e');
    }
  }

// Fetch pending bets count with error handling
  Future<int> _fetchPendingBetsCount(
      String associationId, String userId) async {
    try {
      return await _associationService.fetchPendingBetsCount(
          associationId, userId);
    } catch (e) {
      throw Exception('Failed to fetch pending bets count: $e');
    }
  }

  Future<void> _onJoinNewAssociation(
      JoinNewAssociation event, Emitter<AssociationState> emit) async {
    emit(AssociationLoading());

    try {
      await _saveSelectedAssociation(event.newAssociation);

      emit(AssociationJoined());
    } catch (e) {
      emit(AssociationError('Failed to join association: $e'));
    }
  }

  Future<void> _onLeaveAssociation(
      LeaveAssociation event, Emitter<AssociationState> emit) async {
    final currentState = state;
    emit(AssociationLoading());

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _emitLeaveError(emit, currentState, 'User not authenticated');
        return;
      }

      final otherAdminsResponse = await supabase
          .from('association_members')
          .select('user_id, permissions')
          .eq('association_id', event.associationId)
          .neq('user_id', userId);

      final currentUserResponse = await supabase
          .from('association_members')
          .select('permissions')
          .eq('association_id', event.associationId)
          .eq('user_id', userId)
          .single();

      final currentUserPermissions =
          Map<String, dynamic>.from(currentUserResponse['permissions']);

      bool currentUserHasAllPermissions =
          currentUserPermissions['hasAllPermissions'] == true;

      bool otherMembersHaveAllPermissions = otherAdminsResponse.any((admin) {
        final permissions = Map<String, dynamic>.from(admin['permissions']);
        return permissions['hasAllPermissions'] == true;
      });

      if (currentUserHasAllPermissions && !otherMembersHaveAllPermissions) {
        _emitLeaveError(emit, currentState,
            'You cannot leave the association as you are the only member with management permissions.');
        return;
      }

      await supabase
          .from('association_members')
          .delete()
          .eq('user_id', userId)
          .eq('association_id', event.associationId);

      final remainingAssociationsResponse = await supabase
          .from('association_members')
          .select('association_id')
          .eq('user_id', userId);

      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove('selected_association');

      if (remainingAssociationsResponse.isEmpty) {
        emit(NoAssociationsLeft());
      } else {
        emit(AssociationLeave());
      }
    } catch (e) {
      _emitLeaveError(
          emit, currentState, 'Failed to leave association: ${e.toString()}');
    }
  }

  void _emitLeaveError(Emitter<AssociationState> emit,
      AssociationState currentState, String message) {
    if (currentState is AssociationLoaded) {
      emit(AssociationLoaded(
        selectedAssociation: currentState.selectedAssociation,
        memberData: currentState.memberData,
        members: currentState.members,
        pendingBaksCount: currentState.pendingBaksCount,
        pendingBetsCount: currentState.pendingBetsCount,
        pendingAproveBaksCount: currentState.pendingAproveBaksCount,
        errorMessage: message,
      ));
    } else {
      emit(AssociationError(message));
    }
  }

  Future<void> _onRefreshPendingBaks(
      RefreshPendingAproveBaks event, Emitter<AssociationState> emit) async {
    final currentState = state;
    if (currentState is AssociationLoaded) {
      try {
        final pendingAproveBaksCount = await _associationService
            .fetchPendingAproveBaksCount(event.associationId);

        emit(currentState.copyWith(
            pendingAproveBaksCount: pendingAproveBaksCount));
      } catch (e) {
        emit(AssociationError('Failed to refresh pending approve baks: $e'));
      }
    }
  }

  // New method for handling refresh of Baks and Bets
  Future<void> _onRefreshBaksAndBets(
      RefreshBaksAndBets event, Emitter<AssociationState> emit) async {
    final currentState = state;
    if (currentState is AssociationLoaded) {
      try {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) {
          emit(AssociationError('User not authenticated'));
          return;
        }

        final pendingBaksCount = await _associationService
            .fetchPendingBaksCount(event.associationId, userId);
        final pendingBetsCount = await _associationService
            .fetchPendingBetsCount(event.associationId, userId);

        emit(currentState.copyWith(
          pendingBaksCount: pendingBaksCount,
          pendingBetsCount: pendingBetsCount,
        ));
      } catch (e) {
        emit(AssociationError('Failed to refresh Baks and Bets: $e'));
      }
    }
  }

  void _onClearAssociationError(
      ClearAssociationError event, Emitter<AssociationState> emit) {
    if (state is AssociationLoaded) {
      emit((state as AssociationLoaded).copyWith(errorMessage: null));
    }
  }

  void _emitError(Emitter<AssociationState> emit, String message) {
    emit(AssociationError(message));
  }
}
