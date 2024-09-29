import 'dart:convert';
import 'package:equatable/equatable.dart';

class InviteModel extends Equatable {
  final String id;
  final String associationId;
  final String inviteKey;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isExpired;
  final Map<String, dynamic>? permissions; // Add permissions field

  const InviteModel({
    required this.id,
    required this.associationId,
    required this.inviteKey,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    required this.isExpired,
    this.permissions, // Include permissions
  });

  factory InviteModel.fromMap(Map<String, dynamic> map) {
    return InviteModel(
      id: map['id'],
      associationId: map['association_id'],
      inviteKey: map['invite_key'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      expiresAt:
          map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      isExpired: map['is_expired'],
      permissions: map['permissions'] != null
          ? jsonDecode(map['permissions']) as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'association_id': associationId,
      'invite_key': inviteKey,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_expired': isExpired,
      'permissions': jsonEncode(permissions), // Store permissions as JSON
    };
  }

  @override
  List<Object?> get props => [
        id,
        associationId,
        inviteKey,
        createdBy,
        createdAt,
        expiresAt,
        isExpired,
        permissions, // Add permissions to props
      ];
}
