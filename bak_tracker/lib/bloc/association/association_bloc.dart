import 'dart:convert';
import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/services/widget_service.dart';
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
    on<RefreshPendingApproveBaks>(_onRefreshPendingBaks);
    on<RefreshBaksAndBets>(_onRefreshBaksAndBets);
    on<JoinNewAssociation>(_onJoinNewAssociation);
    _loadSelectedAssociation();
  }

  // Loading the previously selected association from local storage.
  Future<void> _loadSelectedAssociation() async {
    _prefs ??= await SharedPreferences.getInstance();
    final String? savedAssociationData =
        _prefs?.getString('selected_association');

    if (savedAssociationData != null) {
      final selectedAssociation =
          AssociationModel.fromMap(jsonDecode(savedAssociationData));
      add(SelectAssociation(selectedAssociation: selectedAssociation));
    }
  }

  // Save the currently selected association to local storage.
  Future<void> _saveSelectedAssociation(AssociationModel association) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!
        .setString('selected_association', jsonEncode(association.toMap()));
  }

// Handle selecting an association.
  Future<void> _onSelectAssociation(
      SelectAssociation event, Emitter<AssociationState> emit) async {
    emit(AssociationLoading());
    try {
      await _saveSelectedAssociation(event.selectedAssociation);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return _emitError(emit, 'User not authenticated');
      }

      // Fetch all necessary data concurrently.
      final responses = await Future.wait([
        _fetchMemberData(event.selectedAssociation.id, userId),
        _fetchMembers(event.selectedAssociation.id),
        _fetchPendingBaksCount(event.selectedAssociation.id, userId),
        _fetchPendingApproveBaksCount(event.selectedAssociation.id),
        _fetchPendingBetsCount(event.selectedAssociation.id, userId),
        _fetchAssociation(event.selectedAssociation.id),
      ]);

      final AssociationMemberModel memberData =
          responses[0] as AssociationMemberModel;
      final List<AssociationMemberModel> members =
          responses[1] as List<AssociationMemberModel>;
      final int pendingBaksCount = responses[2] as int;
      final int pendingApproveBaksCount = responses[3] as int;
      final int pendingBetsCount = responses[4] as int;
      final AssociationModel updatedAssociation =
          responses[5] as AssociationModel;

      // Update the widget with the selected association's name, chucked drinks, and debt.
      await WidgetService.updateDrinkInfo(
        updatedAssociation.name,
        memberData.baksConsumed.toString(),
        memberData.baksReceived.toString(),
      );

      emit(AssociationLoaded(
        selectedAssociation: updatedAssociation,
        memberData: memberData,
        members: members,
        pendingBaksCount: pendingBaksCount,
        pendingBetsCount: pendingBetsCount,
        pendingAproveBaksCount: pendingApproveBaksCount,
      ));
    } catch (e) {
      _emitError(emit, 'Failed to select association: ${e.toString()}');
    }
  }

  // Fetch member data from the database.
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

  // Fetch the list of members.
  Future<List<AssociationMemberModel>> _fetchMembers(
      String associationId) async {
    return await _associationService.fetchMembers(associationId);
  }

  // Fetch pending baks count.
  Future<int> _fetchPendingBaksCount(
      String associationId, String userId) async {
    return await _associationService.fetchPendingBaksCount(
        associationId, userId);
  }

  // Fetch pending approve baks count.
  Future<int> _fetchPendingApproveBaksCount(String associationId) async {
    return await _associationService.fetchPendingAproveBaksCount(associationId);
  }

  // Fetch pending bets count.
  Future<int> _fetchPendingBetsCount(
      String associationId, String userId) async {
    return await _associationService.fetchPendingBetsCount(
        associationId, userId);
  }

  // Fetch updated association data from the database
  Future<AssociationModel> _fetchAssociation(String associationId) async {
    final response = await Supabase.instance.client
        .from('associations')
        .select()
        .eq('id', associationId)
        .single();
    return AssociationModel.fromMap(response);
  }

  // Handle joining a new association.
  Future<void> _onJoinNewAssociation(
      JoinNewAssociation event, Emitter<AssociationState> emit) async {
    emit(AssociationLoading());
    try {
      await _saveSelectedAssociation(event.newAssociation);
      emit(AssociationJoined());
    } catch (e) {
      _emitError(emit, 'Failed to join association: ${e.toString()}');
    }
  }

  // Handle leaving an association.
  Future<void> _onLeaveAssociation(
      LeaveAssociation event, Emitter<AssociationState> emit) async {
    final currentState = state;
    emit(AssociationLoading());

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return _emitLeaveError(emit, currentState, 'User not authenticated');
      }

      // Check if the user is the only admin with full permissions.
      final currentUserResponse =
          await _fetchMemberData(event.associationId, userId);
      if (currentUserResponse.permissions
          .hasPermission(PermissionEnum.hasAllPermissions)) {
        final otherAdmins =
            await _fetchOtherAdmins(event.associationId, userId);
        if (otherAdmins.isEmpty) {
          return _emitLeaveError(emit, currentState,
              'You cannot leave the association as you are the only member with management permissions.');
        }
      }

      // Remove user from the association.
      await Supabase.instance.client
          .from('association_members')
          .delete()
          .eq('user_id', userId)
          .eq('association_id', event.associationId);

      final remainingAssociations = await _fetchRemainingAssociations(userId);

      // Remove saved association and handle state accordingly.
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove('selected_association');

      if (remainingAssociations.isEmpty) {
        emit(NoAssociationsLeft());
      } else {
        emit(AssociationLeave());
      }
    } catch (e) {
      _emitLeaveError(
          emit, currentState, 'Failed to leave association: ${e.toString()}');
    }
  }

  // Fetch other admins with full permissions.
  Future<List<dynamic>> _fetchOtherAdmins(
      String associationId, String userId) async {
    return await Supabase.instance.client
        .from('association_members')
        .select('user_id, permissions')
        .eq('association_id', associationId)
        .neq('user_id', userId);
  }

  // Fetch remaining associations for the user.
  Future<List<dynamic>> _fetchRemainingAssociations(String userId) async {
    return await Supabase.instance.client
        .from('association_members')
        .select('association_id')
        .eq('user_id', userId);
  }

  // Emit an error during association leave process.
  void _emitLeaveError(Emitter<AssociationState> emit,
      AssociationState currentState, String message) {
    if (currentState is AssociationLoaded) {
      emit(currentState.copyWith(errorMessage: message));
    } else {
      emit(AssociationError(message));
    }
  }

  // Emit an error in general.
  void _emitError(Emitter<AssociationState> emit, String message) {
    emit(AssociationError(message));
  }

  // Handle refreshing pending baks.
  Future<void> _onRefreshPendingBaks(
      RefreshPendingApproveBaks event, Emitter<AssociationState> emit) async {
    final currentState = state;
    if (currentState is AssociationLoaded) {
      try {
        final pendingApproveBaksCount =
            await _fetchPendingApproveBaksCount(event.associationId);
        emit(currentState.copyWith(
            pendingAproveBaksCount: pendingApproveBaksCount));
      } catch (e) {
        _emitError(
            emit, 'Failed to refresh pending approve baks: ${e.toString()}');
      }
    }
  }

  // Handle refreshing baks and bets.
  Future<void> _onRefreshBaksAndBets(
      RefreshBaksAndBets event, Emitter<AssociationState> emit) async {
    final currentState = state;
    if (currentState is AssociationLoaded) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          return _emitError(emit, 'User not authenticated');
        }

        final pendingBaksCount =
            await _fetchPendingBaksCount(event.associationId, userId);
        final pendingBetsCount =
            await _fetchPendingBetsCount(event.associationId, userId);
        emit(currentState.copyWith(
          pendingBaksCount: pendingBaksCount,
          pendingBetsCount: pendingBetsCount,
        ));
      } catch (e) {
        _emitError(emit, 'Failed to refresh baks and bets: ${e.toString()}');
      }
    }
  }

  // Clear the association error.
  void _onClearAssociationError(
      ClearAssociationError event, Emitter<AssociationState> emit) {
    if (state is AssociationLoaded) {
      emit((state as AssociationLoaded).copyWith(errorMessage: null));
    }
  }
}
