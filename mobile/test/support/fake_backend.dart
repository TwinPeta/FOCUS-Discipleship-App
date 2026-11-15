import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focus_1/core/connectivity/connectivity_service.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/learning/domain/playback_controller.dart';
import 'package:focus_1/features/auth/presentation/providers/auth_providers.dart';

import 'fakes.dart';

/// Replaces the whole API-backed data layer with the in-memory test doubles in
/// `test/support/fakes/`. The app ships none of this: it always talks to the
/// real API, so every test that needs data starts from here (or from
/// [fakeContainer] / `pumpFcuApp`).
List<Override> fakeBackend() => [
  passwordSealProvider.overrideWith((ref) => fakePasswordDigest),
  authRepositoryProvider.overrideWith((ref) => FakeAuthRepository()),
  profileRepositoryProvider.overrideWith((ref) => FakeProfileRepository()),
  institutionRepositoryProvider.overrideWith(
    (ref) => FakeInstitutionRepository(),
  ),
  communityRepositoryProvider.overrideWith((ref) => FakeCommunityRepository()),
  memberRepositoryProvider.overrideWith(
    (ref) => FakeMemberRepository(
      roster: ref.read(communityRepositoryProvider).getMembers,
      isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
    ),
  ),
  notificationRepositoryProvider.overrideWith(
    (ref) => FakeNotificationRepository(),
  ),
  membershipRepositoryProvider.overrideWith(
    (ref) => FakeMembershipRepository(
      notifications: ref.read(notificationRepositoryProvider),
    ),
  ),
  joinRequestRepositoryProvider.overrideWith(
    (ref) => FakeJoinRequestRepository(
      notifications: ref.read(notificationRepositoryProvider),
    ),
  ),
  warningRepositoryProvider.overrideWith((ref) => FakeWarningRepository()),
  suspensionRepositoryProvider.overrideWith(
    (ref) => FakeSuspensionRepository(),
  ),
  moderationQueueRepositoryProvider.overrideWith(
    (ref) => FakeModerationQueueRepository(
      notifications: ref.read(notificationRepositoryProvider),
      warnings: ref.read(warningRepositoryProvider),
    ),
  ),
  postRepositoryProvider.overrideWith(
    (ref) => FakePostRepository(
      isHidden: ref.read(moderationQueueRepositoryProvider).isHidden,
      isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
    ),
  ),
  storiesRepositoryProvider.overrideWith((ref) => FakeStoriesRepository()),
  resourceRepositoryProvider.overrideWith((ref) => FakeResourceRepository()),
  prayerRepositoryProvider.overrideWith(
    (ref) => FakePrayerRepository(
      isHidden: ref.read(moderationQueueRepositoryProvider).isHidden,
      isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
      notifications: ref.read(notificationRepositoryProvider),
    ),
  ),
  testimonyRepositoryProvider.overrideWith(
    (ref) => FakeTestimonyRepository(
      isHidden: ref.read(moderationQueueRepositoryProvider).isHidden,
      isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
    ),
  ),
  pathwayRepositoryProvider.overrideWith((ref) => FakePathwayRepository()),
  messagingRepositoryProvider.overrideWith(
    // Read lazily so the store survives profile/guardian changes.
    (ref) => FakeMessagingRepository(
      isRestricted: () => ref.read(messagingRestrictedProvider),
      isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
    ),
  ),
  reportRepositoryProvider.overrideWith(
    (ref) => FakeReportRepository(
      moderation: ref.read(moderationQueueRepositoryProvider),
    ),
  ),
  moderationRepositoryProvider.overrideWith(
    (ref) => FakeModerationRepository(
      currentUserId: () =>
          ref.read(authControllerProvider).valueOrNull?.accountId,
    ),
  ),
  activityRepositoryProvider.overrideWith((ref) => FakeActivityRepository()),
  learningRepositoryProvider.overrideWith((ref) => FakeLearningRepository()),
  meetingRepositoryProvider.overrideWith(
    (ref) => FakeMeetingRepository(
      communityById: ref.read(communityRepositoryProvider).getCommunityById,
    ),
  ),
  privacyRepositoryProvider.overrideWith((ref) => FakePrivacyRepository()),
  // Scripted playback: the position advances on a timer, nothing is downloaded.
  playbackFactoryProvider.overrideWith(
    (ref) =>
        (video, {required start, required dataSaver}) async =>
            FakePlaybackController(
              duration: video.duration,
              start: start,
              dataSaver: dataSaver,
            ),
  ),
  connectivityServiceProvider.overrideWith((ref) {
    final service = FakeConnectivityService();
    ref.onDispose(service.dispose);
    return service;
  }),
];

/// A container wired to the test doubles; [overrides] win over the defaults.
ProviderContainer fakeContainer({List<Override> overrides = const []}) =>
    ProviderContainer(overrides: [...fakeBackend(), ...overrides]);
