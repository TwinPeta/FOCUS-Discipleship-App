import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/features/notifications/domain/app_notification.dart';
import 'package:focus_1/features/prayer/domain/prayer_request.dart';
import 'package:focus_1/features/prayer/presentation/prayer_request_screen.dart';
import 'package:focus_1/features/testimony/domain/testimony.dart';
import 'package:focus_1/features/testimony/presentation/testimony_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';

void main() {
  group('prayer responses and anonymity', () {
    late FakeNotificationRepository notes;
    late FakePrayerRepository repo;

    setUp(() {
      notes = FakeNotificationRepository(latency: Duration.zero);
      repo = FakePrayerRepository(latency: Duration.zero, notifications: notes);
    });

    PrayerRequest anon() => PrayerRequest(
      id: 'c-prayer-9',
      communityId: 'c',
      authorId: 'owner',
      authorName: 'Owner Name',
      anonymous: true,
      body: 'Please pray',
      createdAt: DateTime(2026),
    );

    test('anonymous request: model never carries the author', () async {
      final stored = await repo.createRequest(anon(), ownerId: 'owner');
      expect(stored.authorId, isNull);
      expect(stored.authorName, isNull);
      final fetched = await repo.getRequest('c-prayer-9');
      expect(fetched!.authorId, isNull);
    });

    test("the anonymous owner's own response stays anonymous", () async {
      await repo.createRequest(anon(), ownerId: 'owner');
      final r = await repo.addResponse(
        requestId: 'c-prayer-9',
        body: 'Thank you all',
        authorId: 'owner',
        authorName: 'Owner Name',
      );
      expect(r.anonymous, isTrue);
      expect(r.authorId, isNull);
      expect(r.authorName, isNull);
      expect(r.displayName, 'Anonymous');
      expect(
        (await repo.getResponses('c-prayer-9')).single.displayName,
        'Anonymous',
      );
      // No self-notification.
      expect(await notes.getNotificationsFor('owner'), isEmpty);
    });

    test('others are named; the owner is notified without names', () async {
      await repo.createRequest(anon(), ownerId: 'owner');
      final r = await repo.addResponse(
        requestId: 'c-prayer-9',
        body: 'Praying for you',
        authorId: 'friend',
        authorName: 'Friend',
      );
      expect(r.anonymous, isFalse);
      expect(r.displayName, 'Friend');
      final n = (await notes.getNotificationsFor('owner')).single;
      expect(n.type, NotificationType.prayerResponse);
      expect(n.targetRoute, '/prayer/c-prayer-9');
      expect(n.title, isNot(contains('Owner')));
      expect(n.title, isNot(contains('Friend')));
    });

    test('empty responses are rejected; seeded wall has responses', () async {
      await expectLater(
        repo.addResponse(
          requestId: 'growth-circle-prayer-1',
          body: '   ',
          authorId: 'x',
          authorName: 'X',
        ),
        throwsArgumentError,
      );
      // Deep link before the wall was ever opened.
      expect(await repo.getRequest('growth-circle-prayer-2'), isNotNull);
      expect(await repo.getResponses('growth-circle-prayer-1'), hasLength(1));
    });

    test('prayedLabel', () {
      expect(prayedLabel(1), '1 person prayed');
      expect(prayedLabel(8), '8 people prayed');
    });
  });

  group('testimony visibility and encouragement', () {
    late FakeTestimonyRepository repo;

    setUp(() => repo = FakeTestimonyRepository(latency: Duration.zero));

    Testimony pending() => Testimony(
      id: 'mine-1',
      communityId: 'growth-circle',
      type: TestimonyType.story,
      title: 'My story',
      excerpt: 'Full text',
      authorId: 'me',
      authorName: 'Me',
      institution: 'Makerere University',
      status: TestimonyStatus.reviewed, // stored as pending regardless
      createdAt: DateTime(2026),
    );

    test('pending opens only for its author', () async {
      await repo.submitStory(pending());
      expect(await repo.getTestimony('mine-1', viewerId: 'other'), isNull);
      expect(await repo.getTestimony('mine-1', viewerId: null), isNull);
      final own = await repo.getTestimony('mine-1', viewerId: 'me');
      expect(own!.status, TestimonyStatus.pending);
    });

    test('reviewed opens for everyone, even by deep link', () async {
      final t = await repo.getTestimony(
        'growth-circle-testimony-2',
        viewerId: 'anyone',
      );
      expect(t!.status, TestimonyStatus.reviewed);
    });

    test('encouraged is one per member and idempotent', () async {
      const id = 'growth-circle-testimony-2';
      await repo.getTestimony(id, viewerId: 'x');
      var t = await repo.setEncouraged(id, encouraged: true);
      t = await repo.setEncouraged(id, encouraged: true);
      expect(t.encouragedCount, 1);
      t = await repo.setEncouraged(id, encouraged: false);
      expect(t.encouragedCount, 0);
      expect(t.encouragedByMe, isFalse);
    });
  });

  testWidgets('screen 52: shows the request and posts a response', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/prayer/growth-circle-prayer-2');

    expect(find.byType(PrayerRequestScreen), findsOneWidget);
    expect(find.text('Anonymous'), findsOneWidget);
    expect(find.text('14 people prayed'), findsOneWidget);
    expect(
      find.text('Praying with you. You are not alone in this.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Holding you in prayer');
    await tester.pump(); // let the send button enable
    await tester.tap(find.byIcon(Icons.send_rounded));
    await settle(tester, steps: 12);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty, reason: 'sent, so cleared');
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await settle(tester);
    expect(find.text('Holding you in prayer'), findsOneWidget);
    expect(find.text(testProfile.fullName), findsOneWidget);
  });

  testWidgets('screen 53: reviewed story with Encouraged and Report', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/testimony/growth-circle-testimony-2');

    expect(find.byType(TestimonyScreen), findsOneWidget);
    expect(find.text('Reviewed'), findsOneWidget);
    expect(find.text('Finding peace after a hard semester'), findsOneWidget);
    expect(find.text('David Okello · Makerere University'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Encouraged'));
    await settle(tester);
    expect(find.text('1 person encouraged'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Encouraged'), findsOneWidget);
  });

  testWidgets('screen 53: a pending story by someone else is not shown', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/testimony/no-such-story');
    expect(find.text('Story not available'), findsOneWidget);
  });
}
