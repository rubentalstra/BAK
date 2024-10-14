import 'package:equatable/equatable.dart';

class AssociationRequestModel extends Equatable {
  final String id;
  final String websiteUrl;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? declineReason;

  const AssociationRequestModel({
    required this.id,
    required this.websiteUrl,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.declineReason,
  });

  // Factory method to create AssociationRequestModel from a map (e.g., from Supabase)
  factory AssociationRequestModel.fromMap(Map<String, dynamic> map) {
    return AssociationRequestModel(
      id: map['id'],
      websiteUrl: map['website_url'],
      name: map['name'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      declineReason: map['decline_reason'],
    );
  }

  // Convert AssociationRequestModel to a map (e.g., for inserting into Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'website_url': websiteUrl,
      'name': name,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'decline_reason': declineReason,
    };
  }

  @override
  List<Object?> get props => [
        id,
        websiteUrl,
        name,
        status,
        createdAt,
        updatedAt,
        declineReason,
      ];
}
