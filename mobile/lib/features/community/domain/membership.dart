enum MembershipStatus { none, pending, approved, rejected }

/// Thrown when a membership change breaks the lifecycle
/// none -> pending -> approved | rejected -> none.
class IllegalMembershipTransition implements Exception {
  const IllegalMembershipTransition(this.from, this.to);

  final MembershipStatus from;
  final MembershipStatus to;

  @override
  String toString() =>
      'IllegalMembershipTransition(${from.name} -> ${to.name})';
}

/// Thrown when a user who already has a pending or approved specific
/// membership asks to join a different community.
class MembershipLimitReached implements Exception {
  const MembershipLimitReached(this.existingCommunityId);

  final String? existingCommunityId;

  @override
  String toString() => 'MembershipLimitReached($existingCommunityId)';
}

class Membership {
  const Membership({
    required this.communityId,
    required this.status,
    this.message,
    this.resultSeen = true,
  });

  final String? communityId;
  final MembershipStatus status;

  /// The super-mentor's optional message when declining.
  final String? message;

  /// False right after an approve/decline until the one-time result screen
  /// (27 or 28) has been shown.
  final bool resultSeen;

  bool get hasUnseenResult =>
      !resultSeen &&
      (status == MembershipStatus.approved ||
          status == MembershipStatus.rejected);

  Membership markResultSeen() =>
      Membership(communityId: communityId, status: status, message: message);

  static const empty = Membership(
    communityId: null,
    status: MembershipStatus.none,
  );

  /// Legal next states for each status. Everything else throws.
  static const _legal = <MembershipStatus, Set<MembershipStatus>>{
    MembershipStatus.none: {MembershipStatus.pending},
    MembershipStatus.pending: {
      MembershipStatus.approved,
      MembershipStatus.rejected,
    },
    MembershipStatus.approved: {MembershipStatus.none},
    MembershipStatus.rejected: {MembershipStatus.none},
  };

  static bool canTransition(MembershipStatus from, MembershipStatus to) =>
      _legal[from]!.contains(to);

  /// Returns the membership after moving to [next]; throws
  /// [IllegalMembershipTransition] for any other move. [communityId] is
  /// required when entering `pending` and cleared when returning to `none`.
  Membership transitionTo(
    MembershipStatus next, {
    String? communityId,
    String? message,
  }) {
    if (!canTransition(status, next)) {
      throw IllegalMembershipTransition(status, next);
    }
    if (next == MembershipStatus.none) return empty;
    if (next == MembershipStatus.pending) {
      if (communityId == null) {
        throw ArgumentError.notNull('communityId');
      }
      return Membership(communityId: communityId, status: next);
    }
    // approved / rejected: a fresh result the user has not seen yet.
    return Membership(
      communityId: this.communityId,
      status: next,
      message: next == MembershipStatus.rejected ? message : null,
      resultSeen: false,
    );
  }

  /// True when a pending or approved membership blocks joining another.
  bool get isActive =>
      status == MembershipStatus.pending || status == MembershipStatus.approved;
}
