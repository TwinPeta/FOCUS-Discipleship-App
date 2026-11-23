import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/network/media_uploader.dart';
import 'package:focus_1/core/network/token_vault.dart';
import 'package:focus_1/core/storage/json_patch.dart';
import 'package:focus_1/core/storage/local_database.dart';
import 'package:focus_1/core/storage/media_stash.dart';
import 'package:focus_1/core/sync/outbox.dart';
import 'package:focus_1/features/activity/data/remote_activity_repository.dart';
import 'package:focus_1/features/activity/domain/activity_event.dart';
import 'package:focus_1/features/auth/data/remote_auth_repository.dart';
import 'package:focus_1/features/community/data/remote_membership_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/feed/data/remote_post_repository.dart';
import 'package:focus_1/features/landing/data/remote_stories_repository.dart';
import 'package:focus_1/features/feed/domain/comment.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/community/data/people_directory.dart';
import 'package:focus_1/features/profile/data/remote_profile_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fakes.dart';

http.Response _json(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// A fake server: [handler] answers while [up]; otherwise the network fails.
class _Server {
  _Server(this.handler);

  final http.Response Function(http.Request request) handler;
  bool up = true;
  final List<http.Request> seen = [];

  late final client = MockClient((request) async {
    if (!up) throw http.ClientException('no route to host');
    seen.add(request);
    return handler(request);
  });
}

class _KeepInPlace extends MediaStash {
  const _KeepInPlace();
  @override
  Future<String> keep(String path, String localId) async => path;
  @override
  Future<void> discard(String path) async {}
}

const _me = {
  'id': 'u1',
  'email': 'grace@fcu.test',
  'full_name': 'Grace Namuli',
  'username': 'grace',
  'birthdate': '2003-04-01',
  'country': 'UG',
  'institution_type': 'university',
};

({ApiClient api, MemoryLocalDatabase db, FakeConnectivityService net})
_client(_Server server, {bool online = true}) {
  final db = MemoryLocalDatabase();
  final net = FakeConnectivityService(online: online);
  final tokens = TokenStore()
    ..save(access: 'a1', refresh: 'r1')
    ..remember(accountId: 'u1', email: 'grace@fcu.test');
  final api = ApiClient(
    baseUrl: 'https://api.test/v1',
    client: server.client,
    tokens: tokens,
    cache: db,
    connectivity: net,
  );
  return (api: api, db: db, net: net);
}

void main() {
  group('saved replies (ApiClient + LocalDatabase)', () {
    test('a GET that cannot reach the server returns the saved reply', () async {
      final server = _Server((_) => _json(200, {'id': 'u1', 'n': 1}));
      final c = _client(server);
      expect(await c.api.get('/me'), {'id': 'u1', 'n': 1});

      server.up = false;
      expect(await c.api.get('/me'), {'id': 'u1', 'n': 1});
      expect(c.net.isOnline, isFalse, reason: 'the failure is reported');
    });

    test('while offline the saved reply comes back without the network', () async {
      final server = _Server((_) => _json(200, {'items': []}));
      final c = _client(server);
      await c.api.get('/pathways');
      c.net.setOnline(false);
      final before = server.seen.length;
      expect(await c.api.get('/pathways'), {'items': []});
      expect(server.seen.length, before);
    });

    test('a server error also falls back; a 404 does not', () async {
      var status = 200;
      final server = _Server((_) => _json(status, {'id': 'x'}));
      final c = _client(server);
      await c.api.get('/posts/x');
      status = 503;
      expect(await c.api.get('/posts/x'), {'id': 'x'});
      status = 404;
      await expectLater(c.api.get('/posts/x'), throwsA(isA<ApiException>()));
    });

    test('nothing saved: the network error is thrown', () async {
      final server = _Server((_) => _json(200, {}))..up = false;
      final c = _client(server);
      await expectLater(
        c.api.get('/me'),
        throwsA(isA<ApiException>().having((e) => e.isNetwork, 'net', true)),
      );
    });

    test('a clock in the query does not change the saved key', () {
      final c = _client(_Server((_) => _json(200, {})));
      expect(
        c.api.cacheKey('/communities/c1/meetings', query: {'now': 'a'}),
        c.api.cacheKey('/communities/c1/meetings', query: {'now': 'b'}),
      );
      expect(
        c.api.cacheKey('/me'),
        isNot(c.api.cacheKey('/me', auth: false)),
      );
    });

    test('replies are saved per account', () async {
      final server = _Server((_) => _json(200, {'who': 'u1'}));
      final c = _client(server);
      await c.api.get('/me');
      c.api.tokens.remember(accountId: 'u2', email: 'b@fcu.test');
      server.up = false;
      await expectLater(c.api.get('/me'), throwsA(isA<ApiException>()));
    });
  });

  group('public replies (landing stories, lookups)', () {
    test('saved while signed out, shown offline, kept after sign-out', () async {
      final server = _Server(
        (_) => _json(200, {
          'stories': [
            {'id': 's1', 'quote': 'Found my people', 'student_name': 'Ann'},
          ],
        }),
      );
      final c = _client(server);
      c.api.tokens.clear(); // signed out, like on the landing page
      final stories = RemoteStoriesRepository(c.api);
      expect(await stories.getStories(), hasLength(1));

      // Signed in later: the same saved copy is used.
      c.api.tokens
        ..save(access: 'a1', refresh: 'r1')
        ..remember(accountId: 'u1', email: 'grace@fcu.test');
      expect(
        c.api.cacheKey('/public/landing'),
        startsWith('public|'),
      );
      await c.db.wipeAccount('u1'); // sign-out of u1

      server.up = false;
      c.api.tokens.clear();
      final offline = await stories.getStories();
      expect(offline.single.quote, 'Found my people');
    });

    test('school lookups are shared, not per account', () {
      final c = _client(_Server((_) => _json(200, {})));
      expect(
        c.api.cacheKey('/lookups/institutions', query: {'q': 'Mak'}),
        'public|GET /lookups/institutions?q=Mak',
      );
      expect(c.api.cacheAccount('/lookups/institutions'), isNull);
      expect(c.api.cacheAccount('/me'), 'u1');
    });
  });

  group('signed in and offline: never sent back to sign-up', () {
    test('the profile and membership load from the saved replies', () async {
      final server = _Server((r) {
        if (r.url.path.endsWith('/me')) return _json(200, _me);
        if (r.url.path.endsWith('/me/communities')) {
          return _json(200, {
            'specific': {
              'community': {'id': 'growth-circle'},
              'membership_status': 'member',
            },
          });
        }
        return _json(404, null);
      });
      final c = _client(server);
      final auth = RemoteAuthRepository(c.api);
      final profiles = RemoteProfileRepository(
        c.api,
        auth,
        MediaUploader(c.api),
      );
      final memberships = RemoteMembershipRepository(c.api);
      await profiles.getProfile('u1');
      await memberships.getMembership();

      server.up = false;
      c.net.setOnline(false);
      expect((await auth.currentSession())?.accountId, 'u1');
      expect((await profiles.getProfile('u1'))?.username, 'grace');
      final membership = await memberships.getMembership();
      expect(membership.status, MembershipStatus.approved);
      expect(membership.communityId, 'growth-circle');
    });
  });

  group('Outbox', () {
    Outbox outbox(ApiClient api, LocalDatabase db, FakeConnectivityService n) =>
        Outbox(
          api: api,
          db: db,
          connectivity: n,
          uploader: MediaUploader(api),
          stash: const _KeepInPlace(),
        );

    test('online: sent at once with its Idempotency-Key', () async {
      final server = _Server((_) => _json(201, {'id': 'srv-1'}));
      final c = _client(server);
      final box = outbox(c.api, c.db, c.net);
      final result = await box.write(
        const OfflineWrite(
          method: 'POST',
          endpoint: '/communities/c1/posts',
          entityType: 'post',
          clientId: 'post-1',
          body: {'text': 'hi'},
        ),
      );
      expect(result.queued, isFalse);
      expect(result.json, {'id': 'srv-1'});
      expect(server.seen.single.headers['Idempotency-Key'], 'post-1');
      expect(await box.pendingCount(), 0);
    });

    test('offline: queued, optimistic reply, saved list patched', () async {
      final server = _Server((_) => _json(200, {'items': <Object>[]}));
      final c = _client(server);
      await c.api.get('/communities/c1/posts', query: {'limit': '20'});
      c.net.setOnline(false);
      final box = outbox(c.api, c.db, c.net);
      const item = {'id': 'post-1', 'text': 'hi', 'pending': true};
      final result = await box.write(
        OfflineWrite(
          method: 'POST',
          endpoint: '/communities/c1/posts',
          entityType: 'post',
          clientId: 'post-1',
          creates: true,
          body: const {'text': 'hi'},
          optimistic: item,
          patchWhere: firstPageOf('/communities/c1/posts'),
          patch: (_, json) => insertItem(json, item),
        ),
      );
      expect(result.queued, isTrue);
      expect(result.json, item);
      expect(await box.pendingCount(), 1);
      final saved = await c.api.get(
        '/communities/c1/posts',
        query: {'limit': '20'},
      );
      expect(itemsOf(saved).single['id'], 'post-1');
    });

    test('rapid toggles keep only the latest', () async {
      final c = _client(_Server((_) => _json(200, {})), online: false);
      final box = outbox(c.api, c.db, c.net);
      for (final liked in [true, false, true]) {
        await box.write(
          OfflineWrite(
            method: liked ? 'PUT' : 'DELETE',
            endpoint: '/posts/p1/like',
            entityType: 'post_like',
            clientId: 'like-$liked-${DateTime.now().microsecondsSinceEpoch}',
            coalesceKey: 'post_like:p1',
          ),
        );
      }
      final jobs = await c.db.pendingJobs('u1');
      expect(jobs, hasLength(1));
      expect(jobs.single.method, 'PUT');
    });

    test('drain: oldest first, temp ids swapped for server ids', () async {
      final server = _Server((r) {
        if (r.url.path.endsWith('/communities/c1/posts')) {
          return _json(201, {'id': 'srv-post'});
        }
        return _json(201, {'id': 'srv-comment'});
      });
      final c = _client(server, online: false);
      final box = outbox(c.api, c.db, c.net);
      await box.write(
        const OfflineWrite(
          method: 'POST',
          endpoint: '/communities/c1/posts',
          entityType: 'post',
          clientId: 'post-17',
          creates: true,
          body: {'text': 'hi'},
        ),
      );
      await box.write(
        const OfflineWrite(
          method: 'POST',
          endpoint: '/posts/post-17/comments',
          entityType: 'comment',
          clientId: 'comment-18',
          creates: true,
          body: {'text': 'first!'},
        ),
      );
      c.net.setOnline(true);
      final result = await box.drain();
      expect(result.sent, 2);
      expect(server.seen.map((r) => r.url.path), [
        '/v1/communities/c1/posts',
        '/v1/posts/srv-post/comments',
      ]);
      expect(await box.pendingCount(), 0);
    });

    test('a refused write is set aside; the rest still go', () async {
      final server = _Server((r) {
        if (r.url.path.contains('bad')) {
          return _json(422, {'code': 'invalid', 'detail': 'Too long'});
        }
        return _json(200, {});
      });
      final c = _client(server, online: false);
      final box = outbox(c.api, c.db, c.net);
      for (final path in ['/posts/bad/comments', '/posts/ok/like']) {
        await box.write(
          OfflineWrite(
            method: 'POST',
            endpoint: path,
            entityType: 'x',
            clientId: path,
          ),
        );
      }
      final result = await box.drain();
      expect(result.sent, 1);
      expect(result.failed, 1);
      expect((await box.failedJobs()).single.lastError, 'Too long');
    });

    test('offline again mid-drain: stops and keeps the job', () async {
      final server = _Server((_) => _json(200, {}))..up = false;
      final c = _client(server, online: false);
      final box = outbox(c.api, c.db, c.net);
      await box.write(
        const OfflineWrite(
          method: 'PUT',
          endpoint: '/posts/p1/like',
          entityType: 'post_like',
          clientId: 'like-1',
        ),
      );
      final result = await box.drain();
      expect(result.stopped, isTrue);
      expect(result.sent, 0);
      final job = (await c.db.pendingJobs('u1')).single;
      expect(job.retryCount, 1);
    });

    test('a staged photo is uploaded once, then its id is sent', () async {
      var mediaSlots = 0;
      final server = _Server((r) {
        if (r.url.path == '/v1/media') {
          mediaSlots++;
          return _json(201, {
            'media_id': 'm1',
            'upload_url': 'https://bucket.test/m1',
          });
        }
        if (r.url.host == 'bucket.test') return _json(200, null);
        if (r.url.path.endsWith('/complete')) return _json(200, {});
        return _json(201, {'id': 'srv-post'});
      });
      final c = _client(server, online: false);
      final box = Outbox(
        api: c.api,
        db: c.db,
        connectivity: c.net,
        uploader: _FakeUploader(c.api, () => mediaSlots++),
        stash: const _KeepInPlace(),
      );
      await box.write(
        const OfflineWrite(
          method: 'POST',
          endpoint: '/communities/c1/posts',
          entityType: 'post',
          clientId: 'post-1',
          body: {'text': 'look'},
          media: [LocalMedia(path: '/tmp/a.jpg', purpose: 'post_photo')],
        ),
      );
      final result = await box.drain();
      expect(result.sent, 1);
      expect(mediaSlots, 1);
      final sent = jsonDecode(server.seen.last.body) as Map<String, dynamic>;
      expect(sent['media_ids'], ['uploaded-1']);
    });

    test('sign-out wipes the account', () async {
      final server = _Server((_) => _json(200, {'id': 'u1'}));
      final c = _client(server);
      await c.api.get('/me');
      c.net.setOnline(false);
      final box = outbox(c.api, c.db, c.net);
      await box.write(
        const OfflineWrite(
          method: 'PUT',
          endpoint: '/posts/p1/like',
          entityType: 'post_like',
          clientId: 'like-1',
        ),
      );
      await box.wipe('u1');
      expect(await box.pendingCount(), 0);
      expect(await c.db.readCache(c.api.cacheKey('/me')), isNull);
    });
  });

  group('staged photos are not left behind', () {
    test('a replaced (coalesced) write drops its photo', () async {
      final stash = _CountingStash();
      final c = _client(_Server((_) => _json(200, {})), online: false);
      final box = Outbox(
        api: c.api,
        db: c.db,
        connectivity: c.net,
        stash: stash,
      );
      for (final n in [1, 2]) {
        await box.write(
          OfflineWrite(
            method: 'PATCH',
            endpoint: '/me',
            entityType: 'profile',
            clientId: 'profile-$n',
            coalesceKey: 'profile_update',
            media: [
              LocalMedia(
                path: '/tmp/me-$n.webp',
                purpose: 'profile_photo',
                field: 'photo_media_id',
                single: true,
              ),
            ],
          ),
        );
      }
      expect(stash.discarded, ['/tmp/me-1.webp']);
      final jobs = await c.db.pendingJobs('u1');
      expect(jobs.single.clientId, 'profile-2');
      expect(await c.db.getMedia(jobs.single.media.single.localId), isNotNull);
    });

    test('dismissing a failed write drops its photo', () async {
      final stash = _CountingStash();
      final c = _client(
        _Server((_) => _json(422, {'detail': 'Too big'})),
        online: false,
      );
      final box = Outbox(
        api: c.api,
        db: c.db,
        connectivity: c.net,
        uploader: _FakeUploader(c.api, () {}),
        stash: stash,
      );
      await box.write(
        const OfflineWrite(
          method: 'POST',
          endpoint: '/communities/c1/posts',
          entityType: 'post',
          clientId: 'post-1',
          media: [LocalMedia(path: '/tmp/a.webp', purpose: 'post_photo')],
        ),
      );
      await box.drain();
      final failed = (await box.failedJobs()).single;
      await box.dismiss(failed);
      expect(stash.discarded, ['/tmp/a.webp']);
      expect(await c.db.getMedia(failed.media.single.localId), isNull);
    });
  });

  group('TokenStore launch', () {
    test('a launch known to be signed out skips the vault', () async {
      final vault = _CountingVault();
      await TokenStore(vault: vault).restore(knownEmpty: true);
      expect(vault.reads, 0);
      await TokenStore(vault: vault).restore();
      expect(vault.reads, 1);
    });

    test('saving and clearing report whether a session is saved', () {
      final seen = <bool>[];
      final store = TokenStore(vault: MemoryTokenVault())
        ..onSavedChanged = seen.add;
      store.save(access: 'a', refresh: 'r');
      store.clear();
      expect(seen, [true, false]);
    });
  });

  group('RemotePostRepository offline', () {
    test('a like and a comment show at once and wait in the outbox', () async {
      final post = {
        'id': 'p1',
        'community_id': 'c1',
        'author': {'id': 'u2', 'full_name': 'Peter'},
        'text': 'Hello',
        'like_count': 2,
        'liked_by_me': false,
        'comment_count': 0,
      };
      final server = _Server((r) {
        if (r.url.path.endsWith('/communities/c1/posts')) {
          return _json(200, {
            'items': [post],
          });
        }
        if (r.url.path.endsWith('/comments')) return _json(200, {'items': []});
        return _json(200, post);
      });
      final c = _client(server);
      final box = Outbox(api: c.api, db: c.db, connectivity: c.net);
      final repo = RemotePostRepository(
        c.api,
        MediaUploader(c.api),
        PeopleDirectory(),
        outbox: box,
      );
      await repo.getPosts('c1', PostScope.specific);
      await repo.getComments('p1');
      server.up = false;
      c.net.setOnline(false);

      final liked = await repo.setLiked('p1', liked: true);
      expect(liked.likedByMe, isTrue);
      expect(liked.likeCount, 3);

      final comment = await repo.addComment(
        Comment(
          id: 'comment-1',
          postId: 'p1',
          author: const Person(
            id: 'u1',
            name: 'Grace',
            role: PersonRole.member,
          ),
          text: 'Amen',
          createdAt: DateTime(2026),
        ),
      );
      expect(comment.text, 'Amen');
      expect(await box.pendingCount(), 2);

      final page = await repo.getPosts('c1', PostScope.specific);
      expect(page.items.single.likedByMe, isTrue);
      expect(page.items.single.commentCount, 1);
      final comments = await repo.getComments('p1');
      expect(comments.single.text, 'Amen');
    });
  });

  group('opening saved items offline', () {
    test('a post never opened online opens from the saved feed', () async {
      final server = _Server((r) {
        if (r.url.path.endsWith('/communities/c1/posts')) {
          return _json(200, {
            'items': [
              {
                'id': 'p9',
                'community_id': 'c1',
                'author': {'id': 'u2', 'full_name': 'Peter'},
                'text': 'Saved in the feed',
              },
            ],
          });
        }
        return _json(200, {'id': 'c1', 'type': 'specific'});
      });
      final c = _client(server);
      await c.api.get('/communities/c1/posts', query: {'limit': '20'});
      server.up = false;
      c.net.setOnline(false);
      // A fresh repository: nothing remembered in memory (app restarted).
      final repo = RemotePostRepository(
        c.api,
        MediaUploader(c.api),
        PeopleDirectory(),
      );
      final post = await repo.getPost('p9');
      expect(post?.body, 'Saved in the feed');
      expect(await repo.getComments('p9'), isEmpty);
    });

    test('a badge check offline returns no badges instead of failing', () async {
      final server = _Server((_) => _json(200, {}))..up = false;
      final c = _client(server, online: false);
      final badges = await RemoteActivityRepository(c.api).record(
        ActivityEvent(
          type: ActivityType.values.first,
          label: 'Prayed',
          at: DateTime(2026),
        ),
      );
      expect(badges, isEmpty);
    });

    test('findEntity finds nested items', () {
      expect(
        findEntity({
          'items': [
            {'id': 'a'},
            {
              'id': 'b',
              'child': {'id': 'c', 'n': 1},
            },
          ],
        }, 'c'),
        {'id': 'c', 'n': 1},
      );
      expect(findEntity({'items': []}, 'x'), isNull);
    });
  });

  group('json_patch', () {
    test('patchEntity changes every copy and keeps untouched trees', () {
      final json = {
        'items': [
          {'id': 'a', 'n': 1},
          {'id': 'b', 'n': 1},
        ],
      };
      final out = patchEntity(json, 'a', (m) => m..['n'] = 2) as Map;
      expect((out['items'] as List)[0], {'id': 'a', 'n': 2});
      expect(identical(patchEntity(json, 'zz', (m) => m), json), isTrue);
    });

    test('insertItem and removeEntity', () {
      final json = {
        'items': [
          {'id': 'a'},
        ],
      };
      final added = insertItem(json, {'id': 'b'}) as Map;
      expect((added['items'] as List).first, {'id': 'b'});
      expect(identical(insertItem(added, {'id': 'b'}), added), isTrue);
      final removed = removeEntity(added, 'a') as Map;
      expect(removed['items'], [
        {'id': 'b'},
      ]);
    });
  });
}

class _FakeUploader extends MediaUploader {
  _FakeUploader(super.api, this.onUpload);
  final void Function() onUpload;
  var _n = 0;

  @override
  Future<String> uploadPhoto(String path, {required String purpose}) async {
    onUpload();
    return 'uploaded-${++_n}';
  }
}

class _CountingStash extends MediaStash {
  _CountingStash();
  final discarded = <String>[];
  @override
  Future<String> keep(String path, String localId) async => path;
  @override
  Future<void> discard(String path) async => discarded.add(path);
}

class _CountingVault extends MemoryTokenVault {
  var reads = 0;
  @override
  Future<SavedSession?> read() {
    reads++;
    return super.read();
  }
}
