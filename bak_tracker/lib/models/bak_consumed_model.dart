class BakConsumedModel {
  final String id;
  final String takerId;
  final String associationId;
  final String? boardYearId;
  final int amount;
  final String approvalStatus;
  final String? approvedBy;
  final DateTime createdAt;

  BakConsumedModel({
    required this.id,
    required this.takerId,
    required this.associationId,
    this.boardYearId,
    required this.amount,
    required this.approvalStatus,
    this.approvedBy,
    required this.createdAt,
  });

  factory BakConsumedModel.fromMap(Map<String, dynamic> map) {
    return BakConsumedModel(
      id: map['id'],
      takerId: map['taker_id'],
      associationId: map['association_id'],
      boardYearId: map['board_year_id'],
      amount: map['amount'],
      approvalStatus: map['approval_status'],
      approvedBy: map['approved_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taker_id': takerId,
      'association_id': associationId,
      'board_year_id': boardYearId,
      'amount': amount,
      'approval_status': approvalStatus,
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
