class UserModel {
  final String id;
  final String name;
  final String bio;
  final String? fcmToken;
  final DateTime createdAt;
  final String? profileImagePath;

  UserModel({
    required this.id,
    required this.name,
    required this.bio,
    this.fcmToken,
    required this.createdAt,
    this.profileImagePath,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      bio: map['bio'],
      fcmToken: map['fcm_token'],
      createdAt: DateTime.parse(map['created_at']),
      profileImagePath: map['profile_image_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'profile_image_path': profileImagePath,
    };
  }
}
