/// An encouraging reply on a prayer request (screen 52).
class PrayerResponse {
  /// When [anonymous] is true (the request's anonymous author replying),
  /// the author is dropped here so no screen or log can expose it.
  const PrayerResponse({
    required this.id,
    required this.requestId,
    String? authorId,
    String? authorName,
    this.anonymous = false,
    required this.body,
    required this.createdAt,
  }) : authorId = anonymous ? null : authorId,
       authorName = anonymous ? null : authorName;

  final String id;
  final String requestId;
  final String? authorId;
  final String? authorName;
  final bool anonymous;
  final String body;
  final DateTime createdAt;

  String get displayName => anonymous ? 'Anonymous' : (authorName ?? 'Member');
}
