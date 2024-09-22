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

class RefreshPendingBaks extends AssociationEvent {
  final String associationId;

  RefreshPendingBaks(this.associationId);
}
