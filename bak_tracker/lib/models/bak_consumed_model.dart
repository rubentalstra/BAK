import 'package:bak_tracker/models/user_model.dart';
import 'package:equatable/equatable.dart';

class BakConsumedModel extends Equatable {
  final String id;
  final UserModel taker;
  final String associationId;
  final int amount;
  final String status;
  final String? approvedBy;
  final DateTime createdAt;

  const BakConsumedModel({
    required this.id,
    required this.taker,
    required this.associationId,
    required this.amount,
    required this.status,
    this.approvedBy,
    required this.createdAt,
  });

  factory BakConsumedModel.fromMap(Map<String, dynamic> map) {
    return BakConsumedModel(
      id: map['id'],
      taker: UserModel.fromMap(map['taker_id']),
      associationId: map['association_id'],
      amount: map['amount'],
      status: map['status'],
      approvedBy: map['approved_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taker_id': taker.toMap(),
      'association_id': associationId,
      'amount': amount,
      'status': status,
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Override props for Equatable
  @override
  List<Object?> get props =>
      [id, taker, associationId, amount, status, approvedBy, createdAt];
}
