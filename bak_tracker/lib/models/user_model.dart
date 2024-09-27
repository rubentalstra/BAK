import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String bio;
  final String? fcmToken;
  final DateTime createdAt;
  final String? profileImage;

  const UserModel({
    required this.id,
    required this.name,
    required this.bio,
    this.fcmToken,
    required this.createdAt,
    this.profileImage,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      bio: map['bio'],
      fcmToken: map['fcm_token'],
      createdAt: DateTime.parse(map['created_at']),
      profileImage: map['profile_image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'profile_image': profileImage,
    };
  }

  // Override props for Equatable
  @override
  List<Object?> get props => [id, name, bio, fcmToken, createdAt, profileImage];
}
