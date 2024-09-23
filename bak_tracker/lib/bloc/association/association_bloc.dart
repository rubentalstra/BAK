import 'dart:convert';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'association_event.dart';
import 'association_state.dart';

class AssociationBloc extends Bloc<AssociationEvent, AssociationState> {
  SharedPreferences? _prefs; // Cached SharedPreferences instance

  AssociationBloc() : super(AssociationInitial()) {
    on<SelectAssociation>(_onSelectAssociation);
    on<LeaveAssociation>(_onLeaveAssociation);
    on<ClearAssociationError>(_onClearAssociationError);
    on<RefreshPendingBaks>(_onRefreshPendingBaks);
    on<JoinNewAssociation>(_onJoinNewAssociation);
    _loadSelectedAssociation(); // Load from storage when initialized
  }

  // Load saved association from SharedPreferences
  Future<void> _loadSelectedAssociation() async {
    _prefs ??= await SharedPreferences.getInstance();
    final String? selectedAssociationData =
        _prefs?.getString('selected_association');

    if (selectedAssociationData != null) {
      final associationMap =
          jsonDecode(selectedAssociationData) as Map<String, dynamic>;
      final selectedAssociation = AssociationModel.fromMap(associationMap);

      // Fetch and load member data for the association
      add(SelectAssociation(selectedAssociation: selectedAssociation));
    }
  }

  // Save selected association to SharedPreferences
  Future<void> _saveSelectedAssociation(AssociationModel association) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!
        .setString('selected_association', jsonEncode(association.toMap()));
  }

  // Fetch members for the selected association
  Future<List<AssociationMemberModel>> _fetchMembers(
      String associationId) async {
    final supabase = Supabase.instance.client;
    final List<dynamic> response = await supabase
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

  // Handle selection of an association
  Future<void> _onSelectAssociation(
      SelectAssociation event, Emitter<AssociationState> emit) async {
    emit(AssociationLoading());

    try {
      // Save the selected association to preferences
      await _saveSelectedAssociation(event.selectedAssociation);

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(AssociationError('User not authenticated'));
        return;
      }

      // Fetch permissions for the current user
      final response = await supabase
          .from('association_members')
          .select()
          .eq('user_id', userId)
          .eq('association_id', event.selectedAssociation.id)
          .single();

      if (response.isEmpty) {
        emit(AssociationError('Failed to load association member data.'));
        return;
      }

      final memberData = AssociationMemberModel.fromMap(response);

      // Fetch all members for the selected association
      final members = await _fetchMembers(event.selectedAssociation.id);

      // Fetch the updated pending baks count for the association
      final responsePendingBaks = await supabase
          .from('bak_consumed')
          .select()
          .eq('association_id', event.selectedAssociation.id)
          .eq('status', 'pending');

      final pendingCount = responsePendingBaks.length;

      emit(AssociationLoaded(
        selectedAssociation: event.selectedAssociation,
        memberData: memberData,
        members: members, // Pass members list
        pendingBaksCount: pendingCount, // Initialize pending baks count
      ));
    } catch (e) {
      _emitError(emit, 'Failed to select association: $e');
    }
  }

  // Add this method in AssociationBloc class
  Future<AssociationMemberModel> _fetchMemberData(String associationId) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Fetch member data for the current user
    final response = await supabase
        .from('association_members')
        .select()
        .eq('user_id', userId)
        .eq('association_id', associationId)
        .single();

    if (response.isEmpty) {
      throw Exception('Failed to load association member data.');
    }

    return AssociationMemberModel.fromMap(response);
  }

  // Handle joining a new association in AssociationBloc
  Future<void> _onJoinNewAssociation(
      JoinNewAssociation event, Emitter<AssociationState> emit) async {
    emit(AssociationLoading());

    try {
      await _saveSelectedAssociation(event.newAssociation);

      // Emit join success state
      emit(AssociationJoined());
    } catch (e) {
      emit(AssociationError('Failed to join association: $e'));
    }
  }

// Handle leaving the association
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

      // Fetch all members of the association excluding the current user
      final otherAdminsResponse = await supabase
          .from('association_members')
          .select('user_id, permissions')
          .eq('association_id', event.associationId)
          .neq('user_id', userId); // Exclude current user

      // Fetch current user's permissions
      final currentUserResponse = await supabase
          .from('association_members')
          .select('permissions')
          .eq('association_id', event.associationId)
          .eq('user_id', userId)
          .single();

      final currentUserPermissions =
          Map<String, dynamic>.from(currentUserResponse['permissions']);

      // Check if the current user has all permissions
      bool currentUserHasAllPermissions =
          currentUserPermissions['hasAllPermissions'] == true;

      // Check if other members have all permissions
      bool otherMembersHaveAllPermissions = otherAdminsResponse.any((admin) {
        final permissions = Map<String, dynamic>.from(admin['permissions']);
        return permissions['hasAllPermissions'] == true;
      });

      // If the current user has all permissions and no other members have all permissions
      if (currentUserHasAllPermissions && !otherMembersHaveAllPermissions) {
        // Emit error without changing the current state
        _emitLeaveError(emit, currentState,
            'You cannot leave the association as you are the only member with management permissions.');
        return;
      }

      // Proceed with removing the user from the association_members table
      await supabase
          .from('association_members')
          .delete()
          .eq('user_id', userId)
          .eq('association_id', event.associationId);

      // Check if the user is still part of any associations
      final remainingAssociationsResponse = await supabase
          .from('association_members')
          .select('association_id')
          .eq('user_id', userId);

      // Clear the saved association from SharedPreferences
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove('selected_association');

      if (remainingAssociationsResponse.isEmpty) {
        // If no associations remain, emit a state to redirect to NoAssociationScreen
        emit(NoAssociationsLeft());
      } else {
        // Emit leave success state
        emit(AssociationLeave());
      }
    } catch (e) {
      // Emit the error and keep the current state unchanged
      _emitLeaveError(
          emit, currentState, 'Failed to leave association: ${e.toString()}');
    }
  }

// Updated emitLeaveError method to preserve current state
  void _emitLeaveError(Emitter<AssociationState> emit,
      AssociationState currentState, String message) {
    // Log the error message to ensure it's being captured
    // print('Emitting leave error: $message');

    // Check if the current state is AssociationLoaded to preserve it
    if (currentState is AssociationLoaded) {
      // Emit the error message but keep the current state unchanged
      emit(AssociationLoaded(
        selectedAssociation: currentState.selectedAssociation,
        memberData: currentState.memberData,
        members: currentState.members,
        pendingBaksCount: currentState.pendingBaksCount,
        errorMessage: message, // Ensure this error message is passed
      ));
    } else {
      // Emit a generic error if not in AssociationLoaded state
      emit(AssociationError(message)); // Ensure the message is passed
    }
  }

  void _emitError(Emitter<AssociationState> emit, String message) {
    // Log the error message to ensure it's being captured
    // print('Emitting general error: $message');

    emit(AssociationError(message));
  }

  // Handler for RefreshPendingBaks event
  Future<void> _onRefreshPendingBaks(
      RefreshPendingBaks event, Emitter<AssociationState> emit) async {
    final currentState = state;
    if (currentState is AssociationLoaded) {
      final supabase = Supabase.instance.client;

      try {
        // Fetch the updated pending baks count for the association
        final response = await supabase
            .from('bak_consumed')
            .select()
            .eq('association_id', event.associationId)
            .eq('status', 'pending');

        final pendingCount = response.length;

        // Emit the new state with the updated pending baks count
        emit(AssociationLoaded(
          selectedAssociation: currentState.selectedAssociation,
          memberData: currentState.memberData,
          members: currentState.members,
          pendingBaksCount: pendingCount, // Updated pending baks count
        ));
      } catch (e) {
        _emitError(emit, 'Failed to refresh pending baks: $e');
      }
    }
  }

// Clear the error in ClearAssociationError event
  void _onClearAssociationError(
      ClearAssociationError event, Emitter<AssociationState> emit) {
    // Clear the error without triggering other changes
    if (state is AssociationLoaded) {
      emit((state as AssociationLoaded).copyWith(errorMessage: null));
    }
  }
}
