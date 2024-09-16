class BoardYearModel {
  final String id;
  final String associationId;
  final String boardYear;
  final bool isActive;
  final String? description;

  BoardYearModel({
    required this.id,
    required this.associationId,
    required this.boardYear,
    required this.isActive,
    this.description,
  });

  factory BoardYearModel.fromMap(Map<String, dynamic> map) {
    return BoardYearModel(
      id: map['id'],
      associationId: map['association_id'],
      boardYear: map['board_year'],
      isActive: map['is_active'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'association_id': associationId,
      'board_year': boardYear,
      'is_active': isActive,
      'description': description,
    };
  }
}
