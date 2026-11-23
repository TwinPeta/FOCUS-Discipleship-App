import '../../../core/network/api_client.dart';
import '../../../core/storage/json_patch.dart';
import '../../../core/sync/outbox.dart';
import '../../community/domain/person.dart';
import '../domain/message.dart';
import '../domain/thread.dart';
import 'messaging_repository.dart';

/// [MessagingRepository] backed by the FCU API. The server enforces the
/// under-18 limit and blocks; the checks here only save a round trip.
/// Messages arrive when a screen loads (live delivery over the realtime
/// socket is not wired yet).
class RemoteMessagingRepository implements MessagingRepository {
  RemoteMessagingRepository(
    this._api, {
    required this._myId,
    bool Function()? isRestricted,
    Outbox? outbox,
  }) : _isRestricted = isRestricted ?? _never,
       _outbox = outbox ?? Outbox(api: _api);

  final ApiClient _api;
  final Outbox _outbox;
  final String? Function() _myId;
  final bool Function() _isRestricted;
  static bool _never() => false;

  final Map<String, Thread> _threads = {};

  Person _person(Map<String, dynamic>? j, {required bool mentor}) => Person(
    id: (j?['id'] as String?) ?? '',
    name: (j?['full_name'] as String?) ?? '',
    role: mentor ? PersonRole.mentor : PersonRole.member,
    online: j?['online'] == true,
  );

  Thread _thread(Map<String, dynamic> j) {
    final mentor = j['kind'] == 'mentor';
    final thread = Thread(
      id: j['id'] as String,
      participant: _person(objectOf(j['participant']), mentor: mentor),
      roleLabel: mentor ? 'Mentor' : 'Member',
      lastMessage: (j['last_message'] as String?) ?? '',
      lastAt:
          DateTime.tryParse((j['last_message_at'] as String?) ?? '') ??
          DateTime.now(),
      unread: (j['unread_count'] as int?) ?? 0,
    );
    return _threads[thread.id] = thread;
  }

  Message _message(Map<String, dynamic> j, String threadId) {
    final sender = j['sender_id'] as String?;
    return Message(
      id: j['id'] as String,
      threadId: threadId,
      senderId: sender == _myId() ? Message.meId : (sender ?? ''),
      text: (j['text'] as String?) ?? '',
      sentAt:
          DateTime.tryParse((j['sent_at'] as String?) ?? '') ?? DateTime.now(),
      // Written offline: waits on the phone until it can be sent.
      status: j['pending'] == true ? MessageStatus.sending : MessageStatus.sent,
    );
  }

  @override
  Future<List<Thread>> getThreads() async {
    final items = await _api.getAllItems('/conversations');
    return items.map(_thread).toList();
  }

  @override
  Future<Thread?> getThreadById(String id) async {
    final known = _threads[id];
    if (known != null) return known;
    await getThreads();
    return _threads[id];
  }

  @override
  Future<Thread> openOrCreateThread(
    Person participant,
    String roleLabel,
  ) async {
    if (!canMessage(participant)) throw const MessagingRestricted();
    try {
      final json = objectOf(
        await _api.post('/conversations', body: {'user_id': participant.id}),
      );
      if (json == null) throw const ApiException(500, message: 'Empty reply');
      final thread = _thread(json);
      // Keep the role the caller knows (the API only knows mentor/member).
      return _threads[thread.id] = Thread(
        id: thread.id,
        participant: participant,
        roleLabel: roleLabel,
        lastMessage: thread.lastMessage,
        lastAt: thread.lastAt,
        unread: thread.unread,
      );
    } on ApiException catch (e) {
      if (e.code == 'messaging_restricted') throw const MessagingRestricted();
      if (e.code == 'blocked') throw PersonBlocked(participant.id);
      rethrow;
    }
  }

  @override
  Future<void> markRead(String threadId) async {
    await _api.post('/conversations/$threadId/read');
    final t = _threads[threadId];
    if (t != null) _threads[threadId] = t.copyWith(unread: 0);
  }

  @override
  bool canMessage(Person person) => !(_isRestricted() && person.isAdult);

  @override
  Future<List<Message>> getMessages(String threadId) async {
    // The API returns newest first; the conversation shows oldest first.
    final items = await _api.getAllItems('/conversations/$threadId/messages');
    return items.reversed.map((j) => _message(j, threadId)).toList();
  }

  @override
  Future<Message> sendMessage(
    String threadId,
    String text, {
    String? clientId,
  }) async {
    // One key per outgoing message: a retry reuses it (like posts and
    // prayer requests, which key on the client-side id).
    final key =
        '$threadId-${clientId ?? DateTime.now().microsecondsSinceEpoch}';
    final listPath = '/conversations/$threadId/messages';
    final now = apiNow();
    final optimistic = <String, dynamic>{
      'id': key,
      'sender_id': _myId(),
      'text': text,
      'sent_at': now,
      'pending': true,
    };
    try {
      final json = objectOf(
        (await _outbox.write(
          OfflineWrite(
            method: 'POST',
            endpoint: listPath,
            entityType: 'message',
            clientId: key,
            creates: true,
            body: {'text': text},
            optimistic: optimistic,
            // Newest first in the saved reply; the thread list shows it too.
            patch: (k, json) => cachedPathOf(k) == listPath
                ? (k.contains('cursor=') ? json : insertItem(json, optimistic))
                : patchEntity(json, threadId, (m) {
                    m['last_message'] = text;
                    m['last_message_at'] = now;
                    return m;
                  }),
          ),
        )).json,
      );
      if (json == null) throw const ApiException(500, message: 'Empty reply');
      return _message(json, threadId);
    } on ApiException catch (e) {
      if (e.code == 'messaging_restricted') throw const MessagingRestricted();
      if (e.code == 'blocked') throw const PersonBlocked('');
      rethrow;
    }
  }
}
