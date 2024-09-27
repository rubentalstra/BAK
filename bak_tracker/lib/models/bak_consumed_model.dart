import 'package:equatable/equatable.dart';

class BakConsumedModel extends Equatable {
  final String id;
  final String takerId;
  final String associationId;
  final int amount;
  final String status;
  final String? approvedBy;
  final DateTime createdAt;

  const BakConsumedModel({
    required this.id,
    required this.takerId,
    required this.associationId,
    required this.amount,
    required this.status,
    this.approvedBy,
    required this.createdAt,
  });

  factory BakConsumedModel.fromMap(Map<String, dynamic> map) {
    return BakConsumedModel(
      id: map['id'],
      takerId: map['taker_id'],
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
      'taker_id': takerId,
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
      [id, takerId, associationId, amount, status, approvedBy, createdAt];
}
