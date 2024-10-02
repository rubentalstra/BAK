import 'package:bak_tracker/models/user_model.dart';
import 'package:equatable/equatable.dart';

class BakSendModel extends Equatable {
  final String id;
  final UserModel giver;
  final UserModel receiver;
  final String associationId;
  final String? reason;
  final int amount;
  final String status;
  final DateTime createdAt;

  const BakSendModel({
    required this.id,
    required this.giver,
    required this.receiver,
    required this.associationId,
    this.reason,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory BakSendModel.fromMap(Map<String, dynamic> map) {
    return BakSendModel(
      id: map['id'],
      giver: UserModel.fromMap(map['giver_id']),
      receiver: UserModel.fromMap(map['receiver_id']),
      associationId: map['association_id'],
      reason: map['reason'],
      amount: map['amount'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'giver_id': giver.toMap(),
      'receiver_id': receiver.toMap(),
      'association_id': associationId,
      'reason': reason,
      'amount': amount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Override props for Equatable
  @override
  List<Object?> get props =>
      [id, giver, receiver, associationId, reason, amount, status, createdAt];
}
