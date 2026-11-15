import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/activity/domain/activity_event.dart';
import 'package:focus_1/features/prayer/domain/prayer_request.dart';
import 'package:focus_1/features/prayer/presentation/providers/prayer_providers.dart';

import '../support/fakes.dart';
import '../support/fake_backend.dart';

void main() {
  test('anonymous prayer requests carry no author', () async {
    final requests = await FakePrayerRepository().getRequests('growth-circle');
    final anonymous = requests.firstWhere((r) => r.anonymous);

    expect(anonymous.authorId, isNull);
    expect(anonymous.authorName, isNull);
  });

  test(
    'an anonymous request drops any author it is given (no assert reliance)',
    () {
      final request = PrayerRequest(
        id: 'x',
        communityId: 'c',
        authorId: 'u1',
        authorName: 'Someone',
        anonymous: true,
        body: 'b',
        createdAt: DateTime.now(),
      );
      expect(request.authorId, isNull);
      expect(request.authorName, isNull);
      expect(request.toString(), isNot(contains('u1')));
    },
  );

  test('the repository stores anonymous requests without an author', () async {
    final repo = FakePrayerRepository(latency: Duration.zero);
    await repo.createRequest(
      PrayerRequest(
        id: 'anon',
        communityId: 'c',
        authorId: 'u1',
        anonymous: true,
        body: 'b',
        createdAt: DateTime.now(),
      ),
    );
    final stored = (await repo.getRequests('c'))
        .firstWhere((r) => r.id == 'anon');
    expect(stored.authorId, isNull);
  });

  test(
    '"I prayed" toggles once per user and keeps the count in sync',
    () async {
      final container = fakeContainer(
        overrides: [
          prayerRepositoryProvider.overrideWith(
            (ref) => FakePrayerRepository(latency: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        prayerRequestsProvider('growth-circle').notifier,
      );
      final seeded = await container.read(
        prayerRequestsProvider('growth-circle').future,
      );
      final target = seeded.first;
      final initialCount = target.prayedCount;

      await notifier.togglePrayed(target.id);
      var updated = container
          .read(prayerRequestsProvider('growth-circle'))
          .value!
          .firstWhere((r) => r.id == target.id);
      expect(updated.prayedByMe, isTrue);
      expect(updated.prayedCount, initialCount + 1);

      // Tapping again un-prays instead of counting a second time.
      await notifier.togglePrayed(target.id);
      updated = container
          .read(prayerRequestsProvider('growth-circle'))
          .value!
          .firstWhere((r) => r.id == target.id);
      expect(updated.prayedByMe, isFalse);
      expect(updated.prayedCount, initialCount);
    },
  );

  test(
    're-marking the same request never records a second prayed event',
    () async {
      final activity = FakeActivityRepository(latency: Duration.zero);
      final container = fakeContainer(
        overrides: [
          prayerRepositoryProvider.overrideWith(
            (ref) => FakePrayerRepository(latency: Duration.zero),
          ),
          activityRepositoryProvider.overrideWith((ref) => activity),
          moderationRepositoryProvider.overrideWith(
            (ref) => FakeModerationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = prayerRequestsProvider('growth-circle');
      final target = (await container.read(provider.future)).first;
      for (var i = 0; i < 6; i++) {
        await container.read(provider.notifier).togglePrayed(target.id);
      }
      final events = await activity.getEvents();
      expect(events.where((e) => e.type == ActivityType.prayed), hasLength(1));
    },
  );
}
