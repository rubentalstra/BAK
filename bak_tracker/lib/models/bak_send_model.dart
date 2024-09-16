class BakSendModel {
  final String id;
  final String giverId;
  final String receiverId;
  final String associationId;
  final int amount;
  final String status;
  final DateTime createdAt;

  BakSendModel({
    required this.id,
    required this.giverId,
    required this.receiverId,
    required this.associationId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory BakSendModel.fromMap(Map<String, dynamic> map) {
    return BakSendModel(
      id: map['id'],
      giverId: map['giver_id'],
      receiverId: map['receiver_id'],
      associationId: map['association_id'],
      amount: map['amount'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'giver_id': giverId,
      'receiver_id': receiverId,
      'association_id': associationId,
      'amount': amount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
