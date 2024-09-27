import 'package:equatable/equatable.dart';

class Bet extends Equatable {
  final String id;
  final String betCreatorId;
  final String betReceiverId;
  final String associationId;
  final int amount;
  final String status;
  final String? betDescription;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor
  const Bet({
    required this.id,
    required this.betCreatorId,
    required this.betReceiverId,
    required this.associationId,
    required this.amount,
    required this.status,
    this.betDescription,
    this.winnerId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Equatable override to compare Bet objects
  @override
  List<Object?> get props => [
        id,
        betCreatorId,
        betReceiverId,
        associationId,
        amount,
        status,
        betDescription,
        winnerId,
        createdAt,
        updatedAt,
      ];

  // Factory method to create Bet from a Map (e.g., from a database query)
  factory Bet.fromMap(Map<String, dynamic> map) {
    return Bet(
      id: map['id'] as String,
      betCreatorId: map['bet_creator_id'] as String,
      betReceiverId: map['bet_receiver_id'] as String,
      associationId: map['association_id'] as String,
      amount: map['amount'] as int,
      status: map['status'] as String,
      betDescription: map['bet_description'] as String?,
      winnerId: map['winner_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Method to convert Bet object to a Map (e.g., for inserting/updating in the database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bet_creator_id': betCreatorId,
      'bet_receiver_id': betReceiverId,
      'association_id': associationId,
      'amount': amount,
      'status': status,
      'bet_description': betDescription,
      'winner_id': winnerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
