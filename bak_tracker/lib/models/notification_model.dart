import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final DateTime createdAt;
  final String title;
  final String body;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.title,
    required this.body,
  });

  // Factory method to create a NotificationModel from a map (e.g., from Supabase)
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      title: map['title'],
      body: map['body'],
    );
  }

  // Convert NotificationModel to a map (e.g., for inserting into Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'body': body,
    };
  }

  // Override props for Equatable to compare models
  @override
  List<Object?> get props => [id, userId, createdAt, title, body];
}
