enum MembershipStatus { none, pending, approved, rejected }

class Membership {
  const Membership({required this.communityId, required this.status});

  final String? communityId;
  final MembershipStatus status;

  static const empty = Membership(
    communityId: null,
    status: MembershipStatus.none,
  );

  Membership copyWith({String? communityId, MembershipStatus? status}) {
    return Membership(
      communityId: communityId ?? this.communityId,
      status: status ?? this.status,
    );
  }
}
