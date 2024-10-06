// association_event.dart
import 'package:equatable/equatable.dart';
import 'package:bak_tracker/models/association_model.dart';

// Association Events
abstract class AssociationEvent extends Equatable {
  const AssociationEvent();

  @override
  List<Object?> get props => [];
}

class SelectAssociation extends AssociationEvent {
  final AssociationModel selectedAssociation;

  const SelectAssociation({required this.selectedAssociation});

  @override
  List<Object?> get props => [selectedAssociation];
}

class LeaveAssociation extends AssociationEvent {
  final String associationId;

  const LeaveAssociation({required this.associationId});

  @override
  List<Object?> get props => [associationId];
}

class RefreshPendingApproveBaks extends AssociationEvent {
  final String associationId;

  const RefreshPendingApproveBaks(this.associationId);

  @override
  List<Object?> get props => [associationId];
}

class RefreshBaksAndBets extends AssociationEvent {
  final String associationId;

  const RefreshBaksAndBets(this.associationId);

  @override
  List<Object?> get props => [associationId];
}

class ClearAssociationError extends AssociationEvent {
  const ClearAssociationError();
}

class JoinNewAssociation extends AssociationEvent {
  final AssociationModel newAssociation;

  const JoinNewAssociation({required this.newAssociation});

  @override
  List<Object?> get props => [newAssociation];
}
