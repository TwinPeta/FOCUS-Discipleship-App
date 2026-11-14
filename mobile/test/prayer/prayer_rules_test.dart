import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/prayer/data/prayer_repository.dart';
import 'package:focus_1/features/prayer/domain/prayer_request.dart';
import 'package:focus_1/features/prayer/presentation/providers/prayer_providers.dart';

void main() {
  test('anonymous prayer requests carry no author', () async {
    final requests = await FakePrayerRepository().getRequests('growth-circle');
    final anonymous = requests.firstWhere((r) => r.anonymous);

    expect(anonymous.authorId, isNull);
    expect(anonymous.authorName, isNull);
  });

  test('constructing an anonymous request with an author throws', () {
    expect(
      () => PrayerRequest(
        id: 'x',
        communityId: 'c',
        authorId: 'u1',
        anonymous: true,
        body: 'b',
        createdAt: DateTime.now(),
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('"I prayed" toggles once per user and keeps the count in sync', () async {
    final container = ProviderContainer(
      overrides: [
        prayerRepositoryProvider.overrideWith((ref) => FakePrayerRepository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier =
        container.read(prayerRequestsProvider('growth-circle').notifier);
    final seeded =
        await container.read(prayerRequestsProvider('growth-circle').future);
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
  });
}
