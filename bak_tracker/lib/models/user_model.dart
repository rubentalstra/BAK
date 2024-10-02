import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String? bio; // Nullable
  final String? fcmToken; // Nullable
  final String? profileImage; // Nullable

  const UserModel({
    required this.id,
    required this.name,
    this.bio, // Nullable
    this.fcmToken, // Nullable
    this.profileImage, // Nullable
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? 'Unknown ID',
      name: map['name'] ?? 'Unknown Name',
      bio: map['bio'], // This can be null
      fcmToken: map['fcm_token'], // This can be null
      profileImage: map['profile_image'], // This can be null
    );
  }

  // Create an empty factory method for default value
  factory UserModel.empty() {
    return UserModel(
      id: 'Unknown ID',
      name: 'Unknown Name',
      bio: null,
      fcmToken: null,
      profileImage: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'fcm_token': fcmToken,
      'profile_image': profileImage,
    };
  }

  @override
  List<Object?> get props => [id, name, bio, fcmToken, profileImage];
}
