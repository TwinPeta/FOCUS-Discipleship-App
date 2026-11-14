/// What produced a notification. The Notifications *screen* is prompt 3;
/// this prompt only records them.
enum NotificationType {
  requestApproved,
  requestDeclined,
  prayedForYou,
  announcement,
  meetingReminder,
  inactivity,
  moderatorWarning,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.targetRoute,
    required this.createdAt,
    this.body,
    this.readAt,
    this.recipientId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String? body;

  /// Where tapping it goes (e.g. `/request/approved`).
  final String targetRoute;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Who it is for; null means the signed-in user.
  final String? recipientId;

  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    targetRoute: targetRoute,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
    recipientId: recipientId,
  );
}
