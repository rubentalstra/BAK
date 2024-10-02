import 'package:equatable/equatable.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/association_member_model.dart';

// Association States
abstract class AssociationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AssociationInitial extends AssociationState {}

class AssociationLoading extends AssociationState {}

class NoAssociationsLeft extends AssociationState {}

class AssociationLoaded extends AssociationState {
  final AssociationModel selectedAssociation;
  final AssociationMemberModel memberData;
  final List<AssociationMemberModel> members;
  final int pendingBaksCount; // Track the number of pending baks
  final int pendingBetsCount; // Track the number of pending bets
  final int pendingAproveBaksCount; // Track the number of pending approve baks
  final String? errorMessage;

  AssociationLoaded({
    required this.selectedAssociation,
    required this.memberData,
    required this.members,
    required this.pendingBaksCount,
    required this.pendingBetsCount, // Include the pending bets count
    required this.pendingAproveBaksCount, // Include the pending approve baks count
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        selectedAssociation,
        memberData,
        members,
        pendingBaksCount,
        pendingBetsCount,
        pendingAproveBaksCount,
        errorMessage,
      ];

  // Implementing the copyWith method to allow partial updates to state
  AssociationLoaded copyWith({
    AssociationModel? selectedAssociation,
    AssociationMemberModel? memberData,
    List<AssociationMemberModel>? members,
    int? pendingBaksCount,
    int? pendingBetsCount,
    int? pendingAproveBaksCount,
    String? errorMessage,
  }) {
    return AssociationLoaded(
      selectedAssociation: selectedAssociation ?? this.selectedAssociation,
      memberData: memberData ?? this.memberData,
      members: members ?? this.members,
      pendingBaksCount: pendingBaksCount ?? this.pendingBaksCount,
      pendingBetsCount: pendingBetsCount ?? this.pendingBetsCount,
      pendingAproveBaksCount:
          pendingAproveBaksCount ?? this.pendingAproveBaksCount,
      errorMessage: errorMessage, // Explicitly set to null or new value
    );
  }
}

class AssociationError extends AssociationState {
  final String message;

  AssociationError(this.message);

  @override
  List<Object?> get props => [message];
}

class AssociationLeave extends AssociationState {
  @override
  List<Object?> get props => [];
}

class AssociationJoined extends AssociationState {
  @override
  List<Object?> get props => [];
}
