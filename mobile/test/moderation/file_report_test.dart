import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/messaging/data/report_repository.dart';
import 'package:focus_1/features/messaging/domain/report.dart';
import 'package:focus_1/features/moderation/data/moderation_queue_repository.dart';
import 'package:focus_1/features/moderation/data/warning_repository.dart';
import 'package:focus_1/features/moderation/domain/moderation_case.dart';
import 'package:focus_1/features/testimony/data/testimony_repository.dart';

const _sm = UserRole.superMentor;
const _community = 'growth-circle';

Report _report(
  String reporter, {
  ReportTargetType type = ReportTargetType.post,
  String targetId = 'p-1',
  String? author = 'author-1',
  ReportReason reason = ReportReason.harassment,
  String? communityId = _community,
}) => Report(
  targetType: type,
  targetId: targetId,
  targetUserId: author,
  targetUserName: author == null ? null : 'Ann Author',
  reason: reason,
  communityId: communityId,
  preview: 'Some words',
  reporterId: reporter,
  reporterName: 'Reporter $reporter',
);

void main() {
  late FakeModerationQueueRepository queue;

  setUp(() {
    queue = FakeModerationQueueRepository(
      latency: Duration.zero,
      warnings: FakeWarningRepository(latency: Duration.zero),
      seed: const [],
    );
  });

  Future<List<ModerationCase>> open() =>
      queue.getOpenCases(_community, actorRole: _sm);

  test('a first report opens a level 1 case', () async {
    final c = await queue.fileReport(_report('r1'));
    expect(c.level, 1);
    expect(c.isOpen, isTrue);
    expect(c.content, ModeratedContent.post);
    expect(c.authorId, 'author-1');
    expect(c.authorName, 'Ann Author');
    expect(c.preview, 'Some words');
    expect(c.firstReporterName, 'Reporter r1');
    expect(c.reportCount, 1);
    expect(await open(), hasLength(1));
  });

  test('more reports append to the open case, once per reporter', () async {
    await queue.fileReport(_report('r1'));
    await queue.fileReport(
      _report('r2', reason: ReportReason.spamOrFakeProfile),
    );
    await queue.fileReport(_report('r2')); // same person again
    final c = await queue.fileReport(
      _report('r3', reason: ReportReason.spamOrFakeProfile),
    );

    expect(await open(), hasLength(1));
    expect(c.reportCount, 3);
    // Two of three said spam: the case shows the most common reason.
    expect(c.reason, ReportReason.spamOrFakeProfile);
    expect(c.firstReporterName, 'Reporter r1');
  });

  test('a double submit while in flight counts once', () async {
    final slow = FakeModerationQueueRepository(
      latency: const Duration(milliseconds: 20),
      warnings: FakeWarningRepository(latency: Duration.zero),
      seed: const [],
    );
    await Future.wait([
      slow.fileReport(_report('r1')),
      slow.fileReport(_report('r1')),
    ]);
    final cases = await slow.getOpenCases(_community, actorRole: _sm);
    expect(cases.single.reportCount, 1);
  });

  test('after a decision, a new report opens a new case', () async {
    final first = await queue.fileReport(_report('r1'));
    await queue.keep(first.id, actorRole: _sm);
    final second = await queue.fileReport(_report('r2'));
    expect(second.id, isNot(first.id));
    expect(second.reportCount, 1);
  });

  test('comments, prayer requests and testimonies land in the queue', () async {
    await queue.fileReport(
      _report('r1', type: ReportTargetType.comment, targetId: 'c-1'),
    );
    await queue.fileReport(
      _report('r1', type: ReportTargetType.prayerRequest, targetId: 'pr-1'),
    );
    await queue.fileReport(
      _report('r1', type: ReportTargetType.testimony, targetId: 't-1'),
    );
    expect((await open()).map((c) => c.content), [
      ModeratedContent.comment,
      ModeratedContent.prayerRequest,
      ModeratedContent.testimony,
    ]);
  });

  test('invalid reports are refused', () async {
    await expectLater(
      queue.fileReport(_report('r1', type: ReportTargetType.user)),
      throwsArgumentError,
    );
    await expectLater(
      queue.fileReport(_report('r1', communityId: null)),
      throwsArgumentError,
    );
    await expectLater(
      queue.fileReport(_report('author-1')), // own content
      throwsArgumentError,
    );
    await expectLater(
      queue.fileReport(_report('')), // no reporter id
      throwsArgumentError,
    );
    expect(await open(), isEmpty);
  });

  test('anonymous content can be hidden but not warned', () async {
    final c = await queue.fileReport(
      _report(
        'r1',
        type: ReportTargetType.prayerRequest,
        targetId: 'pr-anon',
        author: null,
      ),
    );
    expect(c.authorName, 'Anonymous');
    expect(c.canWarn, isFalse);
    await expectLater(
      queue.warnAuthor(c.id, actorRole: _sm),
      throwsA(isA<ModerationAuthorUnknown>()),
    );
    expect(queue.isHidden('pr-anon'), isFalse); // nothing changed

    await queue.hide(c.id, actorRole: _sm);
    expect(queue.isHidden('pr-anon'), isTrue);
  });

  test(
    'the report repository files community content into the queue',
    () async {
      final reports = FakeReportRepository(
        latency: Duration.zero,
        moderation: queue,
      );
      await reports.submitReport(_report('r1'));
      // A conversation report is stored but is not community moderation.
      await reports.submitReport(
        const Report(
          targetType: ReportTargetType.conversation,
          targetId: 'thread-1',
          targetUserId: 'u-1',
          reason: ReportReason.harassment,
        ),
      );
      expect(reports.reports, hasLength(2));
      expect(await open(), hasLength(1));
    },
  );

  test(
    'a testimony hidden by a moderator leaves the testimonies list',
    () async {
      final testimonies = FakeTestimonyRepository(
        latency: Duration.zero,
        isHidden: queue.isHidden,
      );
      final before = await testimonies.getTestimonies(
        _community,
        viewerId: null,
      );
      final target = before.first;
      final c = await queue.fileReport(
        _report(
          'r1',
          type: ReportTargetType.testimony,
          targetId: target.id,
          author: target.authorId,
        ),
      );
      await queue.hide(c.id, actorRole: _sm);
      final after = await testimonies.getTestimonies(
        _community,
        viewerId: null,
      );
      expect(after.map((t) => t.id), isNot(contains(target.id)));
    },
  );
}
