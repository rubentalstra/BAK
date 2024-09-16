import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  }

  Future<void> _onSelectAssociation(
      SelectAssociation event, Emitter<AssociationState> emit) async {
    emit(AssociationLoading());

    try {
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
}
