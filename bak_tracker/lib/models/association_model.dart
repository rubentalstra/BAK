import 'package:equatable/equatable.dart';

class AssociationModel extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? websiteUrl;
  final String? bakRegulations;

  const AssociationModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.websiteUrl,
    this.bakRegulations,
  });

  // Factory method to create an AssociationModel from a map (e.g., from Supabase)
  factory AssociationModel.fromMap(Map<String, dynamic> map) {
    return AssociationModel(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      websiteUrl: map['website_url'],
      bakRegulations: map['bak_regulations'],
    );
  }

  // Convert AssociationModel to a map (e.g., for inserting into Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'website_url': websiteUrl,
      'bak_regulations': bakRegulations,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, createdAt, updatedAt, websiteUrl, bakRegulations];
}
