import 'package:bak_tracker/core/const/drink_types.dart';

class AlcoholTrackingModel {
  final String id; // Unique ID for tracking
  final String userId; // ID of the user
  final DrinkType drinkType; // The type of drink
  final int amount; // number of drinks consumed
  final DateTime consumedAt; // Timestamp of when the alcohol was consumed

  AlcoholTrackingModel({
    required this.id,
    required this.userId,
    required this.drinkType,
    required this.amount,
    required this.consumedAt,
  });

  // Convert from map for database usage
  factory AlcoholTrackingModel.fromMap(Map<String, dynamic> map) {
    return AlcoholTrackingModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      drinkType:
          DrinkType.values.firstWhere((e) => e.name == map['drink_type']),
      amount: map['drink_amount'],
      consumedAt: DateTime.parse(map['consumed_at']),
    );
  }

  // Convert to map for database usage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'drink_type': drinkType.name,
      'drink_amount': amount,
      'consumed_at': consumedAt.toIso8601String(),
    };
  }
}
