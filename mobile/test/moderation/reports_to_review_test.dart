import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/route_guards.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';
import 'package:focus_1/features/feed/data/post_repository.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/moderation/data/moderation_queue_repository.dart';
import 'package:focus_1/features/moderation/data/warning_repository.dart';
import 'package:focus_1/features/moderation/domain/moderation_case.dart';
import 'package:focus_1/features/moderation/presentation/reports_to_review_screen.dart';
import 'package:focus_1/features/notifications/data/notification_repository.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';
import 'package:focus_1/features/prayer/data/prayer_repository.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

const _sm = UserRole.superMentor;
const _community = 'growth-circle';

void main() {
  late FakeNotificationRepository notifications;
  late FakeWarningRepository warnings;
  late FakeModerationQueueRepository repo;

  setUp(() {
    notifications = FakeNotificationRepository(latency: Duration.zero);
    warnings = FakeWarningRepository(latency: Duration.zero);
    repo = FakeModerationQueueRepository(
      latency: Duration.zero,
      notifications: notifications,
      warnings: warnings,
    );
  });

  Future<List<String>> openIds() async => (await repo.getOpenCases(
    _community,
    actorRole: _sm,
  )).map((c) => c.id).toList();

  group('ModerationQueueRepository', () {
    test('only super-mentors can read or act on the queue', () async {
      for (final role in [null, UserRole.student, UserRole.mentor]) {
        await expectLater(
          repo.getOpenCases(_community, actorRole: role),
          throwsA(isA<NotSuperMentor>()),
        );
        for (final act in [
          repo.hide,
          repo.warnAuthor,
          repo.keep,
          repo.escalate,
        ]) {
          await expectLater(
            act('case-1', actorRole: role),
            throwsA(isA<NotSuperMentor>()),
          );
        }
      }
      expect(await openIds(), ['case-1', 'case-2', 'case-3']);
    });

    test('every outcome is recorded and removes the case', () async {
      expect(
        (await repo.keep('case-1', actorRole: _sm)).outcome,
        ModerationOutcome.kept,
      );
      expect(await openIds(), ['case-2', 'case-3']);
      expect(repo.isHidden('growth-circle-comment-1'), isFalse);

      expect(
        (await repo.hide('case-2', actorRole: _sm)).outcome,
        ModerationOutcome.hidden,
      );
      expect(repo.isHidden('growth-circle-post-3'), isTrue);
      expect(await openIds(), ['case-3']);

      final escalated = await repo.escalate('case-3', actorRole: _sm);
      expect(escalated.outcome, ModerationOutcome.escalated);
      expect(escalated.level, 2);
      expect((await repo.getAdminQueue()).single.id, 'case-3');
      expect(await openIds(), isEmpty);
    });

    test('warn hides the content, creates a warning and notifies', () async {
      await repo.warnAuthor('case-1', actorRole: _sm);
      expect(repo.isHidden('growth-circle-comment-1'), isTrue);

      final w = (await warnings.getWarningsFor('member-4')).single;
      expect(w.acknowledged, isFalse);
      expect(w.reason, 'Harassment or bullying');
      expect(w.preview, startsWith('This group is a waste of time'));

      final n = (await notifications.getNotificationsFor('member-4')).single;
      expect(n.type, NotificationType.moderatorWarning);
      expect(n.targetRoute, '/warning/${w.id}');
      expect(await notifications.getNotifications(), isEmpty);
    });

    test('a decided case cannot be decided again; no double submit', () async {
      await repo.keep('case-1', actorRole: _sm);
      await expectLater(
        repo.hide('case-1', actorRole: _sm),
        throwsA(isA<ModerationCaseClosed>()),
      );
      final slow = FakeModerationQueueRepository(
        latency: const Duration(milliseconds: 10),
        warnings: warnings,
      );
      final first = slow.warnAuthor('case-2', actorRole: _sm);
      await expectLater(
        slow.warnAuthor('case-2', actorRole: _sm),
        throwsA(isA<ModerationCaseClosed>()),
      );
      await first;
      expect(await warnings.getWarningsFor('member-1'), hasLength(1));
    });

    test('hidden content is filtered out of feeds in the data layer', () async {
      final posts = FakePostRepository(
        latency: Duration.zero,
        isHidden: repo.isHidden,
      );
      final prayers = FakePrayerRepository(
        latency: Duration.zero,
        isHidden: repo.isHidden,
      );
      Future<List<String>> postIds() async => (await posts.getPosts(
        _community,
        PostScope.specific,
      )).items.map((p) => p.id).toList();
      expect(await postIds(), contains('growth-circle-post-3'));

      await repo.hide('case-2', actorRole: _sm);
      await repo.warnAuthor('case-3', actorRole: _sm);
      expect(await postIds(), isNot(contains('growth-circle-post-3')));
      expect(
        (await prayers.getRequests(_community)).map((r) => r.id),
        isNot(contains('growth-circle-prayer-3')),
      );
    });
  });

  test('guard: only super-mentors reach /community/:id/manage/reports', () {
    GuardContext ctx(UserRole role) => GuardContext(
      location: Uri.parse('/community/$_community/manage/reports'),
      profile: AsyncValue.data(testProfile),
      membership: const AsyncValue.data(
        Membership(communityId: _community, status: MembershipStatus.approved),
      ),
      session: AsyncValue.data(
        AuthSession(accountId: testProfile.id, email: testProfile.email),
      ),
      role: role,
    );
    expect(runGuards(ctx(UserRole.student)), '/community/$_community/feed');
    expect(runGuards(ctx(UserRole.mentor)), '/community/$_community/feed');
    expect(runGuards(ctx(UserRole.superMentor)), isNull);
  });

  testWidgets('screen: Keep removes the case; warn asks first', (tester) async {
    final container = await pumpFcuApp(tester);
    container.read(debugRoleOverrideProvider.notifier).state = _sm;
    await goTo(tester, container, '/community/$_community/manage/reports');

    expect(find.byType(ReportsToReviewScreen), findsOneWidget);
    expect(find.text('Comment by Isaac Wandera'), findsOneWidget);
    expect(find.text('3 reports · Harassment or bullying'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Keep').first);
    await settle(tester, steps: 12);
    expect(find.text('Comment kept'), findsOneWidget);
    expect(find.text('Comment by Isaac Wandera'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Warn author').first);
    await settle(tester);
    expect(find.text('Warn Faith Nabirye?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('Post by Faith Nabirye'), findsOneWidget);
  });
}
