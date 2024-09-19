import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Association Events
abstract class AssociationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SelectAssociation extends AssociationEvent {
  final AssociationModel selectedAssociation;

  SelectAssociation({required this.selectedAssociation});

  @override
  List<Object?> get props => [selectedAssociation];
}

class LeaveAssociation extends AssociationEvent {
  final String associationId;

  LeaveAssociation({required this.associationId});

  @override
  List<Object?> get props => [associationId];
}

// Association States
abstract class AssociationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AssociationInitial extends AssociationState {}

class AssociationLoading extends AssociationState {}

class AssociationLoaded extends AssociationState {
  final AssociationModel selectedAssociation;
  final AssociationMemberModel memberData;

  AssociationLoaded(
      {required this.selectedAssociation, required this.memberData});

  @override
  List<Object?> get props => [selectedAssociation, memberData];
}

class AssociationError extends AssociationState {
  final String message;

  AssociationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Association Bloc
class AssociationBloc extends Bloc<AssociationEvent, AssociationState> {
  AssociationBloc() : super(AssociationInitial()) {
    on<SelectAssociation>(_onSelectAssociation);
    on<LeaveAssociation>(_onLeaveAssociation);
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

  Future<void> _onSelectAssociation(
      SelectAssociation event, Emitter<AssociationState> emit) async {
    emit(AssociationLoading());

    try {
      // Save the selected association to preferences
      await _saveSelectedAssociation(event.selectedAssociation);

      // Fetch user ID from Supabase auth
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(AssociationError('User not authenticated'));
        return;
      }

      // Fetch permissions from Supabase
      final Map<String, dynamic> response = await supabase
          .from('association_members')
          .select()
          .eq('user_id', userId)
          .eq('association_id', event.selectedAssociation.id)
          .single();

      final memberData = AssociationMemberModel.fromMap(response);

      // Emit the loaded state with association and member data
      emit(AssociationLoaded(
        selectedAssociation: event.selectedAssociation,
        memberData: memberData,
      ));
    } catch (e) {
      emit(AssociationError(e.toString()));
      return;
    }
  }

  // Handle leaving the association
  Future<void> _onLeaveAssociation(
      LeaveAssociation event, Emitter<AssociationState> emit) async {
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
        emit(AssociationError(
            'You cannot leave the association as you are the only member with management permissions.'));
        return;
      }

      // Remove the user from the association_members table
      await supabase
          .from('association_members')
          .delete()
          .eq('user_id', userId)
          .eq('association_id', event.associationId);

      // Clear the saved association from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_association');

      // Emit a new state indicating the user has left the association
      emit(AssociationInitial());
    } catch (e) {
      emit(AssociationError('Failed to leave association: $e'));
    }
  }
}
