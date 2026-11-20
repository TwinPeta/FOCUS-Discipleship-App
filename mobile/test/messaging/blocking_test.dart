import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/messaging/data/messaging_repository.dart';

import '../support/fakes.dart';

/// Blocking is enforced in the repositories: everything a blocked person
/// wrote disappears, and messaging them is refused.
void main() {
  late FakeModerationRepository blocks;

  setUp(() {
    blocks = FakeModerationRepository(
      latency: Duration.zero,
      currentUserId: () => 'me',
    );
  });

  test('you cannot block yourself; block and unblock are idempotent', () async {
    await expectLater(blocks.blockUser('me'), throwsArgumentError);
    await blocks.blockUser('sm-1');
    await blocks.blockUser('sm-1');
    expect(await blocks.getBlockedUserIds(), {'sm-1'});
    await blocks.unblockUser('sm-1');
    await blocks.unblockUser('sm-1');
    expect(blocks.isBlocked('sm-1'), isFalse);
  });

  test('threads with a blocked person are hidden and refused', () async {
    final messaging = FakeMessagingRepository(
      latency: Duration.zero,
      isBlocked: blocks.isBlocked,
    );
    const grace = Person(
      id: 'sm-1',
      name: 'Grace Namuli',
      role: PersonRole.superMentor,
    );
    await blocks.blockUser('sm-1');

    final threads = await messaging.getThreads();
    expect(threads.map((t) => t.participant.id), isNot(contains('sm-1')));
    expect(await messaging.getThreadById('thread-sm-1'), isNull);
    await expectLater(
      messaging.openOrCreateThread(grace, 'Super-mentor'),
      throwsA(isA<PersonBlocked>()),
    );
    await expectLater(
      messaging.sendMessage('thread-sm-1', 'Hello'),
      throwsA(isA<PersonBlocked>()),
    );

    await blocks.unblockUser('sm-1');
    expect(await messaging.getThreadById('thread-sm-1'), isNotNull);
  });

  test('posts and comments by a blocked person are left out', () async {
    final posts = FakePostRepository(
      latency: Duration.zero,
      isBlocked: blocks.isBlocked,
    );
    await blocks.blockUser('sm-1');
    await blocks.blockUser('member-2');

    final page = await posts.getPosts('growth-circle', PostScope.specific);
    expect(page.items.map((p) => p.author.id), isNot(contains('sm-1')));
    expect(await posts.getPost('growth-circle-post-1'), isNull); // by sm-1
    final comments = await posts.getComments('growth-circle-post-photo');
    expect(comments.map((c) => c.author.id), isNot(contains('member-2')));
  });

  test(
    'prayer requests and testimonies by a blocked person are left out',
    () async {
      final prayers = FakePrayerRepository(
        latency: Duration.zero,
        isBlocked: blocks.isBlocked,
      );
      final testimonies = FakeTestimonyRepository(
        latency: Duration.zero,
        isBlocked: blocks.isBlocked,
      );
      final before = await prayers.getRequests('growth-circle');
      final named = before.firstWhere((r) => r.authorId != null);
      final stories = await testimonies.getTestimonies(
        'growth-circle',
        viewerId: null,
      );
      final story = stories.firstWhere((t) => t.authorId != null);

      await blocks.blockUser(named.authorId!);
      await blocks.blockUser(story.authorId!);

      final after = await prayers.getRequests('growth-circle');
      expect(after.map((r) => r.authorId), isNot(contains(named.authorId)));
      // Anonymous requests stay: their author is unknown.
      expect(
        after.where((r) => r.anonymous).length,
        before.where((r) => r.anonymous).length,
      );
      final storiesAfter = await testimonies.getTestimonies(
        'growth-circle',
        viewerId: null,
      );
      expect(storiesAfter.map((t) => t.id), isNot(contains(story.id)));
    },
  );

  test(
    'caregroup rosters leave blocked people out; profiles still resolve',
    () async {
      final members = FakeMemberRepository(
        latency: Duration.zero,
        roster: FakeCommunityRepository().getMembers,
        isBlocked: blocks.isBlocked,
      );
      await blocks.blockUser('member-2');
      final roster = await members.getCommunityMembers('growth-circle');
      expect(roster.map((m) => m.person.id), isNot(contains('member-2')));
      expect(roster.map((m) => m.person.id), contains('sm-1'));
      // The blocked list (screen 55) can still name them.
      expect(
        (await members.getMember('member-2'))!.person.name,
        'Peter Ssentongo',
      );
    },
  );

  test(
    'member profiles show earned badges only and mark mentors verified',
    () async {
      final members = FakeMemberRepository(
        latency: Duration.zero,
        roster: FakeCommunityRepository().getMembers,
      );
      final mentor = (await members.getMember('m-1'))!;
      expect(mentor.verified, isTrue);
      expect(mentor.badges, isNotEmpty);
      expect(mentor.badges.every((b) => b.earned), isTrue);
      expect((await members.getMember('member-4'))!.verified, isFalse);
      expect(await members.getMember('nobody'), isNull);
    },
  );
}
