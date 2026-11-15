import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activity/data/remote_activity_repository.dart';
import '../../features/landing/data/remote_stories_repository.dart';
import '../../features/learning/data/remote_learning_repository.dart';
import '../../features/pathways/data/remote_pathway_repository.dart';
import '../../features/resources/data/remote_resource_repository.dart';
import '../../features/messaging/data/remote_messaging_repository.dart';
import '../../features/messaging/data/remote_moderation_repository.dart';
import '../../features/messaging/data/remote_report_repository.dart';
import '../../features/settings/data/remote_privacy_repository.dart';
import '../../features/notifications/data/remote_notification_repository.dart';
import '../../features/meetings/data/remote_meeting_repository.dart';
import '../../features/moderation/data/remote_moderation_queue_repository.dart';
import '../../features/moderation/data/remote_suspension_repository.dart';
import '../../features/moderation/data/remote_warning_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/remote_auth_repository.dart';
import '../../features/profile/data/remote_profile_repository.dart';
import '../config/api_config.dart';
import '../permissions/app_permissions.dart';
import '../network/api_client.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/community/data/community_repository.dart';
import '../../features/community/data/people_directory.dart';
import '../../features/community/data/remote_community_repository.dart';
import '../../features/community/data/remote_join_request_repository.dart';
import '../../features/community/data/remote_member_repository.dart';
import '../../features/community/data/remote_membership_repository.dart';
import '../../features/community/data/member_repository.dart';
import '../../features/community/data/join_request_repository.dart';
import '../../features/community/data/membership_repository.dart';
import '../../features/feed/data/post_repository.dart';
import '../../features/feed/data/remote_post_repository.dart';
import '../network/media_uploader.dart';
import '../push/device_registration.dart';
import '../realtime/realtime_client.dart';
import '../../features/learning/data/learning_repository.dart';
import '../../features/landing/data/stories_repository.dart';
import '../../features/activity/data/activity_repository.dart';
import '../../features/meetings/data/meeting_repository.dart';
import '../../features/messaging/data/messaging_repository.dart';
import '../../features/messaging/data/moderation_repository.dart';
import '../../features/messaging/data/report_repository.dart';
import '../../features/moderation/data/moderation_queue_repository.dart';
import '../../features/moderation/data/suspension_repository.dart';
import '../../features/moderation/data/warning_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/pathways/data/pathway_repository.dart';
import '../../features/prayer/data/prayer_repository.dart';
import '../../features/prayer/data/remote_prayer_repository.dart';
import '../../features/testimony/data/remote_testimony_repository.dart';
import '../../features/profile/data/institution_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/resources/data/resource_repository.dart';
import '../../features/settings/data/privacy_repository.dart';
import '../../features/testimony/data/testimony_repository.dart';

/// One client (and one set of tokens) for the whole app. Every repository
/// below talks to the real API through it (see [ApiConfig]).
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: ApiConfig.baseUrl);
  ref.onDispose(client.close);
  return client;
});

/// What the sign-up draft stores in place of the password: the password
/// itself, in memory only, until the register call.
final passwordSealProvider = Provider<String Function(String)>(
  (ref) =>
      (password) => password,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => RemoteAuthRepository(ref.watch(apiClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  if (auth is! RemoteAuthRepository) {
    throw StateError('The profile needs the API-backed sign-in');
  }
  return RemoteProfileRepository(ref.watch(apiClientProvider), auth);
});

/// People met through the API, so a tapped name can open a profile.
final institutionRepositoryProvider = Provider<InstitutionRepository>(
  (ref) => RemoteInstitutionRepository(ref.watch(apiClientProvider)),
);

final peopleDirectoryProvider = Provider<PeopleDirectory>(
  (ref) => PeopleDirectory(),
);

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => RemoteCommunityRepository(ref.watch(apiClientProvider)),
);

final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => RemoteMemberRepository(
    ref.watch(apiClientProvider),
    ref.watch(peopleDirectoryProvider),
    isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
  ),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => RemoteNotificationRepository(ref.watch(apiClientProvider)),
);

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => RemoteMembershipRepository(ref.watch(apiClientProvider)),
);

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>(
  (ref) => RemoteJoinRequestRepository(ref.watch(apiClientProvider)),
);

final warningRepositoryProvider = Provider<WarningRepository>(
  (ref) => RemoteWarningRepository(
    ref.watch(apiClientProvider),
    myId: () => ref.read(authControllerProvider).valueOrNull?.accountId,
  ),
);

final suspensionRepositoryProvider = Provider<SuspensionRepository>(
  (ref) => RemoteSuspensionRepository(ref.watch(apiClientProvider)),
);

final moderationQueueRepositoryProvider = Provider<ModerationQueueRepository>(
  (ref) => RemoteModerationQueueRepository(ref.watch(apiClientProvider)),
);

final mediaUploaderProvider = Provider<MediaUploader>(
  (ref) => MediaUploader(ref.watch(apiClientProvider)),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => RemotePostRepository(
    ref.watch(apiClientProvider),
    ref.watch(mediaUploaderProvider),
    ref.watch(peopleDirectoryProvider),
    isHidden: ref.read(moderationQueueRepositoryProvider).isHidden,
  ),
);

final storiesRepositoryProvider = Provider<StoriesRepository>(
  (ref) => RemoteStoriesRepository(ref.watch(apiClientProvider)),
);

final resourceRepositoryProvider = Provider<ResourceRepository>(
  (ref) => RemoteResourceRepository(ref.watch(apiClientProvider)),
);

final prayerRepositoryProvider = Provider<PrayerRepository>(
  (ref) => RemotePrayerRepository(
    ref.watch(apiClientProvider),
    ref.watch(peopleDirectoryProvider),
    isHidden: ref.read(moderationQueueRepositoryProvider).isHidden,
  ),
);

final testimonyRepositoryProvider = Provider<TestimonyRepository>(
  (ref) => RemoteTestimonyRepository(
    ref.watch(apiClientProvider),
    ref.watch(peopleDirectoryProvider),
    isHidden: ref.read(moderationQueueRepositoryProvider).isHidden,
  ),
);

final pathwayRepositoryProvider = Provider<PathwayRepository>(
  (ref) => RemotePathwayRepository(ref.watch(apiClientProvider)),
);

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => RemoteMessagingRepository(
    ref.watch(apiClientProvider),
    myId: () => ref.read(authControllerProvider).valueOrNull?.accountId,
    isRestricted: () => ref.read(messagingRestrictedProvider),
  ),
);

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ref.watch(messagingRepositoryProvider);
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return ref.watch(messagingRepositoryProvider);
});

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => RemoteReportRepository(
    ref.watch(apiClientProvider),
    ref.watch(mediaUploaderProvider),
  ),
);

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => RemoteModerationRepository(
    ref.watch(apiClientProvider),
    ref.watch(peopleDirectoryProvider),
    currentUserId: () =>
        ref.read(authControllerProvider).valueOrNull?.accountId,
  ),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => RemoteActivityRepository(ref.watch(apiClientProvider)),
);

final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => RemoteLearningRepository(ref.watch(apiClientProvider)),
);

final meetingRepositoryProvider = Provider<MeetingRepository>(
  (ref) => RemoteMeetingRepository(ref.watch(apiClientProvider)),
);

final privacyRepositoryProvider = Provider<PrivacyRepository>(
  (ref) => RemotePrivacyRepository(ref.watch(apiClientProvider)),
);

/// Runtime permissions (camera, photos, notifications). Tests use
/// `FakePermissionService` through `fakeBackend()`.
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => const SystemPermissionService(),
);

/// True when the app talks to the real API (not the test fakes, and a base
/// URL is set). Live updates and device registration only run then.
final liveApiEnabledProvider = Provider<bool>(
  (ref) =>
      ApiConfig.baseUrl.isNotEmpty &&
      ref.watch(authRepositoryProvider) is RemoteAuthRepository,
);

/// The realtime socket (`/v1/realtime`). Connected while signed in and
/// closed on sign-out; a no-op client with an empty stream when the API is
/// off. Consumed by `realtimeBindingsProvider`.
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  if (!ref.watch(liveApiEnabledProvider)) return NoopRealtimeClient();
  final client = SocketRealtimeClient(api: ref.watch(apiClientProvider));
  ref.onDispose(client.dispose);
  ref.listen(authSessionProvider, (_, session) {
    if (session == null) {
      client.stop();
    } else {
      client.start();
    }
  }, fireImmediately: true);
  return client;
});

/// Where the push token comes from: [NoPushTokenSource] until Firebase is
/// added (see [PushTokenSource]).
final pushTokenSourceProvider = Provider<PushTokenSource>(
  (ref) => const NoPushTokenSource(),
);

/// Registers the device with `POST /devices` while signed in; null when the
/// API is off. `AuthController.signOut` unregisters it before the tokens go.
final deviceRegistrationProvider = Provider<DeviceRegistration?>((ref) {
  if (!ref.watch(liveApiEnabledProvider)) return null;
  final registration = DeviceRegistration(
    ref.watch(apiClientProvider),
    source: ref.watch(pushTokenSourceProvider),
  );
  ref.listen(authSessionProvider, (_, session) {
    if (session == null) {
      registration.unregister();
    } else {
      registration.register();
    }
  }, fireImmediately: true);
  return registration;
});
