class AssociationModel {
  final String id;
  final String name;
  final DateTime? createdAt;
  final String? logoUrl;

  AssociationModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.logoUrl,
  });

  factory AssociationModel.fromMap(Map<String, dynamic> map) {
    return AssociationModel(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      logoUrl: map['logo_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'logo_url': logoUrl,
    };
  }
}
