import 'association_member_model.dart';

class LeaderboardEntry {
  final int rank;
  final AssociationMemberModel member; // Directly pass the member model

  LeaderboardEntry({
    required this.rank,
    required this.member,
  });

  LeaderboardEntry copyWith({
    int? rank,
    AssociationMemberModel? member,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      member: member ?? this.member,
    );
  }
}
