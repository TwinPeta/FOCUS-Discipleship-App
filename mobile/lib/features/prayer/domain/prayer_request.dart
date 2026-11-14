class PrayerRequest {
  const PrayerRequest({
    required this.id,
    required this.communityId,
    this.authorId,
    this.authorName,
    required this.anonymous,
    required this.body,
    required this.createdAt,
    this.prayedCount = 0,
    this.prayedByMe = false,
  }) : assert(
         anonymous ? authorId == null && authorName == null : true,
         'Anonymous requests must not carry an author.',
       );

  final String id;
  final String communityId;

  /// Null whenever [anonymous] is true — anonymous requests must never
  /// expose the author in any model, log or UI.
  final String? authorId;
  final String? authorName;
  final bool anonymous;
  final String body;
  final DateTime createdAt;
  final int prayedCount;
  final bool prayedByMe;

  PrayerRequest copyWith({int? prayedCount, bool? prayedByMe}) {
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
    );
  }
}
