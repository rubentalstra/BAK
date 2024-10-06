// association_state.dart
import 'package:equatable/equatable.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/association_member_model.dart';

// Association States
abstract class AssociationState extends Equatable {
  const AssociationState();

  @override
  List<Object?> get props => [];
}

class AssociationInitial extends AssociationState {
  const AssociationInitial();
}

class AssociationLoading extends AssociationState {
  const AssociationLoading();
}

class NoAssociationsLeft extends AssociationState {
  const NoAssociationsLeft();
}

class AssociationLoaded extends AssociationState {
  final AssociationModel selectedAssociation;
  final AssociationMemberModel memberData;
  final List<AssociationMemberModel> members;
  final int pendingBaksCount;
  final int pendingBetsCount;
  final int pendingApproveBaksCount;
  final String? errorMessage;

  const AssociationLoaded({
    required this.selectedAssociation,
    required this.memberData,
    required this.members,
    required this.pendingBaksCount,
    required this.pendingBetsCount,
    required this.pendingApproveBaksCount,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        selectedAssociation,
        memberData,
        members,
        pendingBaksCount,
        pendingBetsCount,
        pendingApproveBaksCount,
        errorMessage,
      ];

  AssociationLoaded copyWith({
    AssociationModel? selectedAssociation,
    AssociationMemberModel? memberData,
    List<AssociationMemberModel>? members,
    int? pendingBaksCount,
    int? pendingBetsCount,
    int? pendingApproveBaksCount,
    String? errorMessage,
  }) {
    return AssociationLoaded(
      selectedAssociation: selectedAssociation ?? this.selectedAssociation,
      memberData: memberData ?? this.memberData,
      members: members ?? this.members,
      pendingBaksCount: pendingBaksCount ?? this.pendingBaksCount,
      pendingBetsCount: pendingBetsCount ?? this.pendingBetsCount,
      pendingApproveBaksCount:
          pendingApproveBaksCount ?? this.pendingApproveBaksCount,
      errorMessage: errorMessage,
    );
  }

  AssociationLoaded clearError() {
    return copyWith(errorMessage: null);
  }
}

class AssociationError extends AssociationState {
  final String message;

  const AssociationError(this.message);

  @override
  List<Object?> get props => [message];
}

class AssociationLeft extends AssociationState {
  const AssociationLeft();
}

class AssociationJoined extends AssociationState {
  const AssociationJoined();
}
