import 'dart:convert';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'association_event.dart';
import 'association_state.dart';

class AssociationBloc extends Bloc<AssociationEvent, AssociationState> {
  AssociationBloc() : super(AssociationInitial()) {
    on<SelectAssociation>(_onSelectAssociation);
    on<LeaveAssociation>(_onLeaveAssociation);
    on<RefreshPendingBaks>(_onRefreshPendingBaks); // Register the event handler
    _loadSelectedAssociation(); // Load from storage when initialized
  }

  // Load saved association from SharedPreferences
  Future<void> _loadSelectedAssociation() async {
    final prefs = await SharedPreferences.getInstance();
    final String? selectedAssociationData =
        prefs.getString('selected_association');

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'selected_association', jsonEncode(association.toMap()));
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
      emit(AssociationError(e.toString()));
    }
  }

  // Handle leaving the association
  Future<void> _onLeaveAssociation(
      LeaveAssociation event, Emitter<AssociationState> emit) async {
    final currentState = state;
    emit(AssociationLoading());

    try {
      // Get user and association information
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(AssociationError('User not authenticated'));
        return;
      }

      // Check if the user is the only one with management permissions
      final otherAdminsResponse = await supabase
          .from('association_members')
          .select()
          .eq('association_id', event.associationId)
          .neq('user_id', userId); // Exclude current user

      bool canLeave = false;

      for (final admin in otherAdminsResponse) {
        final permissions = Map<String, dynamic>.from(admin['permissions']);
        if (permissions['hasAllPermissions'] == true) {
          canLeave = true;
          break;
        }
      }

      if (!canLeave) {
        // The user cannot leave because they are the only one with management permissions
        if (currentState is AssociationLoaded) {
          // Keep the state and show an error message
          emit(AssociationLoaded(
            selectedAssociation: currentState.selectedAssociation,
            memberData: currentState.memberData,
            members: currentState.members,
            pendingBaksCount: currentState.pendingBaksCount,
            errorMessage:
                'You cannot leave the association as you are the only member with management permissions.',
          ));
        }
        return;
      }

      // Proceed with removing the user from the association_members table
      await supabase
          .from('association_members')
          .delete()
          .eq('user_id', userId)
          .eq('association_id', event.associationId);

      // Clear the saved association from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_association');

      // Emit a new state indicating the user has successfully left the association
      emit(AssociationInitial());
    } catch (e) {
      if (currentState is AssociationLoaded) {
        // Keep the state and show an error message
        emit(AssociationLoaded(
          selectedAssociation: currentState.selectedAssociation,
          memberData: currentState.memberData,
          members: currentState.members,
          pendingBaksCount: currentState.pendingBaksCount,
          errorMessage: 'Failed to leave association: $e',
        ));
      } else {
        emit(AssociationError('Failed to leave association: $e'));
      }
    }
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
        emit(AssociationError('Failed to refresh pending baks: $e'));
      }
    }
  }
}
