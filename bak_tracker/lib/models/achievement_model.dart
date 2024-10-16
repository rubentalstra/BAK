import 'package:equatable/equatable.dart';

class AchievementModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  const AchievementModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, description, createdAt];
}
