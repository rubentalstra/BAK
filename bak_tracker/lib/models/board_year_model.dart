class BoardYearModel {
  final String id;
  final String associationId;
  final DateTime yearStart;
  final DateTime yearEnd;
  final String? description;

  BoardYearModel({
    required this.id,
    required this.associationId,
    required this.yearStart,
    required this.yearEnd,
    this.description,
  });

  factory BoardYearModel.fromMap(Map<String, dynamic> map) {
    return BoardYearModel(
      id: map['id'],
      associationId: map['association_id'],
      yearStart: DateTime.parse(map['year_start']),
      yearEnd: DateTime.parse(map['year_end']),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'association_id': associationId,
      'year_start': yearStart.toIso8601String(),
      'year_end': yearEnd.toIso8601String(),
      'description': description,
    };
  }
}
