class PrayerRequest {
  /// Anonymous requests never keep an author: [authorId] and [authorName]
  /// are dropped here (not by an assert, which release builds strip), so no
  /// model, log or screen can expose them.
  const PrayerRequest({
    required this.id,
    required this.communityId,
    String? authorId,
    String? authorName,
    required this.anonymous,
    required this.body,
    required this.createdAt,
    this.prayedCount = 0,
    this.prayedByMe = false,
    this.responseCount = 0,
  }) : authorId = anonymous ? null : authorId,
       authorName = anonymous ? null : authorName;

  final String id;
  final String communityId;

  /// Always null when [anonymous] is true.
  final String? authorId;
  final String? authorName;
  final bool anonymous;
  final String body;
  final DateTime createdAt;
  final int prayedCount;
  final bool prayedByMe;

  /// Encouragements written under the request ("Respond").
  final int responseCount;

  PrayerRequest copyWith({
    int? prayedCount,
    bool? prayedByMe,
    int? responseCount,
  }) {
    return PrayerRequest(
      id: id,
      communityId: communityId,
      authorId: authorId,
      authorName: authorName,
      anonymous: anonymous,
      body: body,
      createdAt: createdAt,
      prayedCount: prayedCount ?? this.prayedCount,
      prayedByMe: prayedByMe ?? this.prayedByMe,
      responseCount: responseCount ?? this.responseCount,
    );
  }

  @override
  String toString() =>
      'PrayerRequest($id, anonymous: $anonymous, prayed: $prayedCount)';
}
