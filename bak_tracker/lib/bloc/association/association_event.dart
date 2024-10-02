import 'package:equatable/equatable.dart';
import 'package:bak_tracker/models/association_model.dart';

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

class RefreshPendingApproveBaks extends AssociationEvent {
  final String associationId;

  RefreshPendingApproveBaks(this.associationId);
}

class RefreshBaksAndBets extends AssociationEvent {
  final String associationId;

  RefreshBaksAndBets(this.associationId);

  @override
  List<Object?> get props => [associationId];
}

class ClearAssociationError extends AssociationEvent {}

class JoinNewAssociation extends AssociationEvent {
  final AssociationModel newAssociation;

  JoinNewAssociation({required this.newAssociation});

  @override
  List<Object?> get props => [newAssociation];
}
