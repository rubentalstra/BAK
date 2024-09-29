import 'package:equatable/equatable.dart';

class AssociationRequestModel extends Equatable {
  final String id;
  final String userId;
  final String websiteUrl;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool processed;
  final String? declineReason;

  const AssociationRequestModel({
    required this.id,
    required this.userId,
    required this.websiteUrl,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.processed,
    this.declineReason,
  });

  // Factory method to create AssociationRequestModel from a map (e.g., from Supabase)
  factory AssociationRequestModel.fromMap(Map<String, dynamic> map) {
    return AssociationRequestModel(
      id: map['id'],
      userId: map['user_id'],
      websiteUrl: map['website_url'],
      name: map['name'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      processed: map['processed'],
      declineReason: map['decline_reason'],
    );
  }

  // Convert AssociationRequestModel to a map (e.g., for inserting into Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'website_url': websiteUrl,
      'name': name,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'processed': processed,
      'decline_reason': declineReason,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        websiteUrl,
        name,
        status,
        createdAt,
        updatedAt,
        processed,
        declineReason,
      ];
}
