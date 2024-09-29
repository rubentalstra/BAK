import 'package:equatable/equatable.dart';

class InviteModel extends Equatable {
  final String id;
  final String associationId;
  final String inviteKey;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isExpired;
  final Map<String, dynamic> permissions;

  const InviteModel({
    required this.id,
    required this.associationId,
    required this.inviteKey,
    required this.createdAt,
    this.expiresAt,
    required this.isExpired,
    required this.permissions,
  });

  factory InviteModel.fromMap(Map<String, dynamic> map) {
    return InviteModel(
      id: map['id'],
      associationId: map['association_id'],
      inviteKey: map['invite_key'],
      createdAt: DateTime.parse(map['created_at']),
      expiresAt:
          map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      isExpired: map['is_expired'],
      permissions: map['permissions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'association_id': associationId,
      'invite_key': inviteKey,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_expired': isExpired,
      'permissions': permissions,
    };
  }

  @override
  List<Object?> get props => [
        id,
        associationId,
        inviteKey,
        createdAt,
        expiresAt,
        isExpired,
        permissions,
      ];
}
