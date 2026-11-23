import '../../../core/network/api_client.dart';
import '../../../core/storage/json_patch.dart';
import '../../../core/sync/outbox.dart';
import '../domain/app_notification.dart';
import '../domain/notification_preferences.dart';
import 'notification_repository.dart';

/// [NotificationRepository] backed by the FCU API. The server creates
/// notifications when things happen (a request is decided, someone prays or
/// replies) and honours the user's settings, so [add] does nothing here and
/// notifications for other people are not readable.
class RemoteNotificationRepository implements NotificationRepository {
  RemoteNotificationRepository(this._api, {Outbox? outbox})
    : _outbox = outbox ?? Outbox(api: _api);

  final ApiClient _api;
  final Outbox _outbox;

  static String _stamp() => '${DateTime.now().microsecondsSinceEpoch}';

  /// The app's type for the API's `type` string; null for an unknown one.
  static NotificationType? typeOf(String? t) => _type(t);

  static NotificationType? _type(String? t) {
    switch (t) {
      case 'request_approved':
        return NotificationType.requestApproved;
      case 'request_declined':
        return NotificationType.requestDeclined;
      case 'comment_reply':
        return NotificationType.commentReply;
      case 'prayed_for_you':
        return NotificationType.prayedForYou;
      case 'prayer_response':
        return NotificationType.prayerResponse;
      case 'announcement':
        return NotificationType.announcement;
      case 'meeting_reminder':
        return NotificationType.meetingReminder;
      case 'inactivity':
        return NotificationType.inactivity;
      case 'moderator_warning':
        return NotificationType.moderatorWarning;
      default:
        return null;
    }
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    final items = await _api.getAllItems('/me/notifications');
    return [
      for (final j in items)
        if (_type(j['type'] as String?) case final type?)
          AppNotification(
            id: j['id'] as String,
            type: type,
            title: (j['title'] as String?) ?? '',
            body: j['body'] as String?,
            targetRoute: (j['target_route'] as String?) ?? '/notifications',
            createdAt:
                DateTime.tryParse((j['created_at'] as String?) ?? '') ??
                DateTime.now(),
            readAt: DateTime.tryParse((j['read_at'] as String?) ?? ''),
          ),
    ];
  }

  @override
  Future<List<AppNotification>> getNotificationsFor(String recipientId) async =>
      const [];

  @override
  Future<AppNotification?> add({
    required NotificationType type,
    required String title,
    required String targetRoute,
    String? body,
    String? recipientId,
  }) async => null;

  @override
  Future<void> markRead(String id) async {
    await _outbox.write(
      OfflineWrite(
        method: 'POST',
        endpoint: '/me/notifications/$id/read',
        entityType: 'notification_read',
        clientId: 'read-$id-${_stamp()}',
        coalesceKey: 'notification_read:$id',
        patch: (_, json) => patchEntity(json, id, (m) {
          m['read'] = true;
          m['read_at'] ??= apiNow();
          return m;
        }),
      ),
    );
  }

  @override
  Future<void> markAllRead() async {
    await _outbox.write(
      OfflineWrite(
        method: 'POST',
        endpoint: '/me/notifications/read-all',
        entityType: 'notification_read_all',
        clientId: 'read-all-${_stamp()}',
        coalesceKey: 'notification_read_all',
      ),
    );
  }

  NotificationPreferences _prefs(Object? json) {
    final map = objectOf(json);
    if (map == null) return NotificationPreferences.defaults;
    final channels = (map['channels'] as List?)?.cast<String>() ?? const [];
    final muted = (map['muted'] as List?)?.cast<String>() ?? const [];
    return NotificationPreferences(
      channels: {
        for (final c in DeliveryChannel.values)
          if (channels.contains(c.name)) c,
      },
      muted: {
        for (final c in NotificationCategory.values)
          if (muted.contains(c.name)) c,
      },
    );
  }

  @override
  Future<NotificationPreferences> getPreferences({String? recipientId}) async =>
      _prefs(await _api.get('/me/notification-preferences'));

  @override
  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences, {
    String? recipientId,
  }) async {
    const path = '/me/notification-preferences';
    final body = <String, dynamic>{
      'channels': [for (final c in preferences.channels) c.name],
      'muted': [for (final c in preferences.muted) c.name],
    };
    return _prefs(
      (await _outbox.write(
        OfflineWrite(
          method: 'PUT',
          endpoint: path,
          entityType: 'notification_prefs',
          clientId: 'prefs-${_stamp()}',
          coalesceKey: 'notification_prefs',
          body: body,
          optimistic: body,
          patchWhere: (key) => cachedPathOf(key) == path,
          patch: (_, _) => body,
        ),
      )).json,
    );
  }
}
