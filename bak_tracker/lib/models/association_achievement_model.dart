import 'package:equatable/equatable.dart';

class AssociationAchievementModel extends Equatable {
  final String id;
  final String? associationId;
  final String name;
  final String? description;
  final DateTime createdAt;

  const AssociationAchievementModel({
    required this.id,
    required this.associationId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory AssociationAchievementModel.fromMap(Map<String, dynamic> map) {
    return AssociationAchievementModel(
      id: map['id'],
      associationId: map['association_id'],
      name: map['name'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'association_id': associationId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, associationId, name, description, createdAt];
}
