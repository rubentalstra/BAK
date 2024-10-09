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

class RefreshMemberAchievements extends AssociationEvent {
  final String memberId;

  const RefreshMemberAchievements(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

class UpdateMemberRole extends AssociationEvent {
  final String associationId;
  final String memberId;
  final String newRole;

  const UpdateMemberRole(
      {required this.associationId,
      required this.memberId,
      required this.newRole});

  @override
  List<Object?> get props => [memberId, newRole];
}

class UpdateMemberStats extends AssociationEvent {
  final String associationId;
  final String memberId;
  final int baksConsumed;
  final int baksReceived;
  final int betsWon;
  final int betsLost;

  const UpdateMemberStats({
    required this.associationId,
    required this.memberId,
    required this.baksConsumed,
    required this.baksReceived,
    required this.betsWon,
    required this.betsLost,
  });

  @override
  List<Object?> get props =>
      [associationId, memberId, baksConsumed, baksReceived, betsWon, betsLost];
}
