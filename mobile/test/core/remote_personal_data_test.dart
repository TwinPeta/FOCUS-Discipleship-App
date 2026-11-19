import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/network/media_uploader.dart';
import 'package:focus_1/features/community/data/people_directory.dart';
import 'package:focus_1/features/feed/data/remote_post_repository.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/learning/data/remote_learning_repository.dart';
import 'package:focus_1/features/testimony/data/remote_testimony_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// The member's own choices that used to live only on the phone (hidden
// posts, passed questions, "Encouraged", reflections, the last quiz
// attempt) are now kept by the API. These check each call and its mapping.

http.Response _json(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Routes "METHOD /v1/path" to a canned reply and records every request.
class _Api {
  _Api(this.routes);

  final Map<String, http.Response Function(http.Request)> routes;
  final List<http.Request> seen = [];

  List<String> get calls => [for (final r in seen) '${r.method} ${r.url.path}'];

  ApiClient get client => ApiClient(
    baseUrl: 'https://api.test/v1',
    client: MockClient((request) async {
      seen.add(request);
      final route = routes['${request.method} ${request.url.path}'];
      return route == null ? _json(404, {'code': 'not_found'}) : route(request);
    }),
  );
}

Map<String, dynamic> _question({bool passed = false}) => {
  'id': 'q1',
  'community_id': 'c1',
  'kind': 'question',
  'author': {'id': 'u1', 'full_name': 'Grace', 'username': 'grace'},
  'text': 'Where do you pray on campus?',
  'media': const [],
  'like_count': 0,
  'liked_by_me': false,
  'comment_count': 0,
  'follower_count': 0,
  'following': false,
  'passed_by_me': passed,
  'created_at': '2026-01-01T10:00:00Z',
};

void main() {
  group('RemotePostRepository', () {
    RemotePostRepository repo(_Api api) => RemotePostRepository(
      api.client,
      MediaUploader(api.client),
      PeopleDirectory(),
    );

    test('"Hide this post" is saved on the server, and undone there', () async {
      final api = _Api({
        'PUT /v1/posts/p1/hide': (_) => _json(204, null),
        'DELETE /v1/posts/p1/hide': (_) => _json(204, null),
      });
      final r = repo(api);
      await r.hidePost('p1');
      await r.unhidePost('p1');
      expect(api.calls, ['PUT /v1/posts/p1/hide', 'DELETE /v1/posts/p1/hide']);
    });

    test('a failed hide is not remembered', () async {
      final api = _Api({
        'PUT /v1/posts/p1/hide': (_) => _json(500, {'code': 'internal_error'}),
        'GET /v1/posts/p1': (_) => _json(200, {..._question(), 'id': 'p1'}),
        'GET /v1/communities/c1': (_) =>
            _json(200, {'id': 'c1', 'type': 'specific'}),
      });
      final r = repo(api);
      await expectLater(r.hidePost('p1'), throwsA(isA<ApiException>()));
      expect(await r.getPost('p1'), isNotNull, reason: 'still visible');
    });

    test('"Pass" on a question goes to the server and reads back', () async {
      final api = _Api({
        'GET /v1/posts/q1': (_) => _json(200, _question(passed: true)),
        'GET /v1/communities/c1': (_) =>
            _json(200, {'id': 'c1', 'type': 'specific'}),
        'PUT /v1/posts/q1/pass': (_) => _json(204, null),
        'DELETE /v1/posts/q1/pass': (_) => _json(204, null),
      });
      final r = repo(api);
      final q = await r.getPost('q1');
      expect(q!.kind, PostKind.question);
      expect(q.passedByMe, isTrue);
      await r.setPassed('q1', passed: false);
      await r.setPassed('q1', passed: true);
      expect(api.calls.where((c) => c.contains('/pass')), [
        'DELETE /v1/posts/q1/pass',
        'PUT /v1/posts/q1/pass',
      ]);
    });
  });

  group('RemoteTestimonyRepository', () {
    test('"Encouraged" uses the server and shows its count', () async {
      var encouraged = false;
      final api = _Api({
        'PUT /v1/testimonies/t1/encourage': (_) {
          encouraged = true;
          return _json(200, {'encouraged_count': 4, 'encouraged_by_me': true});
        },
        'GET /v1/testimonies/t1': (_) => _json(200, {
          'id': 't1',
          'community_id': 'c1',
          'format': 'story',
          'title': 'From anxious to anchored',
          'body': 'It changed',
          'media': const [],
          'author': {'id': 'u2', 'full_name': 'David', 'username': 'dk'},
          'status': 'published',
          'encouraged_count': encouraged ? 4 : 3,
          'encouraged_by_me': encouraged,
        }),
      });
      final r = RemoteTestimonyRepository(api.client, PeopleDirectory());
      final before = await r.getTestimony('t1', viewerId: 'me');
      expect(before!.encouragedCount, 3);
      expect(before.encouragedByMe, isFalse);
      final after = await r.setEncouraged('t1', encouraged: true);
      expect(after.encouragedCount, 4);
      expect(after.encouragedByMe, isTrue);
      expect(api.calls, contains('PUT /v1/testimonies/t1/encourage'));
    });
  });

  group('RemoteLearningRepository', () {
    test('a reflection is read from and saved to the server', () async {
      String? sent;
      final api = _Api({
        'GET /v1/resources/d1/reflection': (_) =>
            _json(200, {'text': '', 'updated_at': null}),
        'PUT /v1/resources/d1/reflection': (req) {
          sent = (jsonDecode(req.body) as Map)['text'] as String;
          return _json(200, {
            'text': sent,
            'updated_at': '2026-01-02T08:00:00Z',
          });
        },
      });
      final r = RemoteLearningRepository(api.client);
      expect(await r.getReflection('d1'), isNull, reason: 'none written yet');
      final saved = await r.saveReflection('d1', 'Remain in him.');
      expect(sent, 'Remain in him.');
      expect(saved.text, 'Remain in him.');
      expect(saved.updatedAt.toUtc(), DateTime.utc(2026, 1, 2, 8));
    });

    test('the last quiz attempt comes back as my own choices', () async {
      final api = _Api({
        'GET /v1/quizzes/z1': (_) => _json(200, {
          'id': 'z1',
          'title': 'Foundations review',
          'pass_mark_percent': 60,
          'questions': [
            {
              'id': 'a',
              'text': 'One?',
              'options': [
                {'id': 'a1', 'text': 'x'},
                {'id': 'a2', 'text': 'y'},
              ],
            },
            {
              'id': 'b',
              'text': 'Two?',
              'options': [
                {'id': 'b1', 'text': 'x'},
                {'id': 'b2', 'text': 'y'},
              ],
            },
          ],
          'my_last_attempt': {
            'score': 1,
            'total': 2,
            'passed': false,
            'created_at': '2026-01-02T08:00:00Z',
            'answers': [
              {'question_id': 'a', 'option_id': 'a2'},
            ],
          },
        }),
      });
      final last = await RemoteLearningRepository(api.client).lastAttempt('z1');
      expect(last!.answers, [1, -1], reason: 'b was left out');
      expect(last.correct, 1);
      expect(last.total, 2);
      expect(last.passed, isFalse);
    });

    test('no attempt yet reads as null', () async {
      final api = _Api({
        'GET /v1/quizzes/z1': (_) => _json(200, {
          'id': 'z1',
          'title': 'Quiz',
          'questions': const [],
          'my_last_attempt': null,
        }),
      });
      expect(
        await RemoteLearningRepository(api.client).lastAttempt('z1'),
        isNull,
      );
    });

    test(
      'a document opens from its real link; the type ignores the query',
      () async {
        final api = _Api({
          'GET /v1/resources/doc1': (_) => _json(200, {
            'id': 'doc1',
            'type': 'document',
            'title': 'Study guide',
            'document_url': 'https://cdn.test/files/guide.pdf?sig=abc.def',
            'file_size_bytes': 1572864,
          }),
          'GET /v1/resources/doc2': (_) => _json(200, {
            'id': 'doc2',
            'type': 'document',
            'title': 'Not uploaded',
            'document_url': null,
          }),
        });
        final r = RemoteLearningRepository(api.client);
        final doc = await r.getDocument('doc1');
        expect(doc.format, 'PDF');
        expect(doc.sizeLabel, '1.5 MB');
        expect(doc.url, 'https://cdn.test/files/guide.pdf?sig=abc.def');
        final missing = await r.getDocument('doc2');
        expect(missing.url, isNull);
        expect(missing.format, 'Document');
        expect(missing.sizeLabel, '');
      },
    );
  });
}
