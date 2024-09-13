class UserModel {
  final String id;
  final String name;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.fcmToken,
    required this.createdAt,
  });

  // Factory constructor to create a UserModel from a map (for Supabase data)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      fcmToken: map['fcm_token'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Method to convert a UserModel instance into a map (for inserting/updating data)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
    };
  }
}