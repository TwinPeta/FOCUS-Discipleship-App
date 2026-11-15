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
import '../network/api_client.dart';
import '../utils/password_policy.dart';
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
import '../../features/profile/data/profile_repository.dart';
import '../../features/resources/data/resource_repository.dart';
import '../../features/settings/data/privacy_repository.dart';
import '../../features/testimony/data/testimony_repository.dart';

/// One client (and one set of tokens) for the whole app. Only used when the
/// app is built with `--dart-define=API_BASE_URL=...` (see [ApiConfig]).
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: ApiConfig.baseUrl);
  ref.onDispose(client.close);
  return client;
});

/// What the sign-up draft stores in place of the password: a digest for the
/// fake backend, the password itself (in memory only, until the register
/// call) for the real one.
final passwordSealProvider = Provider<String Function(String)>((ref) {
  if (ApiConfig.useRemote) return (password) => password;
  return fakePasswordDigest;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteAuthRepository(ref.watch(apiClientProvider));
  }
  return FakeAuthRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (ApiConfig.useRemote) {
    final auth = ref.watch(authRepositoryProvider);
    if (auth is RemoteAuthRepository) {
      return RemoteProfileRepository(ref.watch(apiClientProvider), auth);
    }
  }
  return FakeProfileRepository();
});

/// People met through the API, so a tapped name can open a profile.
final peopleDirectoryProvider = Provider<PeopleDirectory>(
  (ref) => PeopleDirectory(),
);

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteCommunityRepository(ref.watch(apiClientProvider));
  }
  return FakeCommunityRepository();
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteMemberRepository(
      ref.watch(apiClientProvider),
      ref.watch(peopleDirectoryProvider),
      isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
    );
  }
  return FakeMemberRepository(
    roster: ref.read(communityRepositoryProvider).getMembers,
    isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteNotificationRepository(ref.watch(apiClientProvider));
  }
  return FakeNotificationRepository();
});

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteMembershipRepository(ref.watch(apiClientProvider));
  }
  return FakeMembershipRepository(
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteJoinRequestRepository(ref.watch(apiClientProvider));
  }
  return FakeJoinRequestRepository(
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final warningRepositoryProvider = Provider<WarningRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteWarningRepository(
      ref.watch(apiClientProvider),
      myId: () => ref.read(authControllerProvider).valueOrNull?.accountId,
    );
  }
  return FakeWarningRepository();
});

final suspensionRepositoryProvider = Provider<SuspensionRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteSuspensionRepository(ref.watch(apiClientProvider));
  }
  return FakeSuspensionRepository();
});

final moderationQueueRepositoryProvider = Provider<ModerationQueueRepository>(
  (ref) => ApiConfig.useRemote
      ? RemoteModerationQueueRepository(ref.watch(apiClientProvider))
      : FakeModerationQueueRepository(
          notifications: ref.read(notificationRepositoryProvider),
          warnings: ref.read(warningRepositoryProvider),
        ),
);

final mediaUploaderProvider = Provider<MediaUploader>(
  (ref) => MediaUploader(ref.watch(apiClientProvider)),
);

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final moderation = ref.read(moderationQueueRepositoryProvider);
  final blocks = ref.read(moderationRepositoryProvider);
  if (ApiConfig.useRemote) {
    return RemotePostRepository(
      ref.watch(apiClientProvider),
      ref.watch(mediaUploaderProvider),
      ref.watch(peopleDirectoryProvider),
      isHidden: moderation.isHidden,
    );
  }
  return FakePostRepository(
    isHidden: moderation.isHidden,
    isBlocked: blocks.isBlocked,
  );
});

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteStoriesRepository(ref.watch(apiClientProvider));
  }
  return FakeStoriesRepository();
});

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteResourceRepository(ref.watch(apiClientProvider));
  }
  return FakeResourceRepository();
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final moderation = ref.read(moderationQueueRepositoryProvider);
  final blocks = ref.read(moderationRepositoryProvider);
  if (ApiConfig.useRemote) {
    return RemotePrayerRepository(
      ref.watch(apiClientProvider),
      ref.watch(peopleDirectoryProvider),
      isHidden: moderation.isHidden,
    );
  }
  return FakePrayerRepository(
    isHidden: moderation.isHidden,
    isBlocked: blocks.isBlocked,
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final testimonyRepositoryProvider = Provider<TestimonyRepository>((ref) {
  final moderation = ref.read(moderationQueueRepositoryProvider);
  final blocks = ref.read(moderationRepositoryProvider);
  if (ApiConfig.useRemote) {
    return RemoteTestimonyRepository(
      ref.watch(apiClientProvider),
      ref.watch(peopleDirectoryProvider),
      isHidden: moderation.isHidden,
    );
  }
  return FakeTestimonyRepository(
    isHidden: moderation.isHidden,
    isBlocked: blocks.isBlocked,
  );
});

final pathwayRepositoryProvider = Provider<PathwayRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemotePathwayRepository(ref.watch(apiClientProvider));
  }
  return FakePathwayRepository();
});

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteMessagingRepository(
      ref.watch(apiClientProvider),
      myId: () => ref.read(authControllerProvider).valueOrNull?.accountId,
      isRestricted: () => ref.read(messagingRestrictedProvider),
    );
  }
  // Read lazily so the store survives profile/guardian changes.
  return FakeMessagingRepository(
    isRestricted: () => ref.read(messagingRestrictedProvider),
    isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
  );
});

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ref.watch(messagingRepositoryProvider);
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return ref.watch(messagingRepositoryProvider);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteReportRepository(
      ref.watch(apiClientProvider),
      ref.watch(mediaUploaderProvider),
    );
  }
  return FakeReportRepository(
    moderation: ref.read(moderationQueueRepositoryProvider),
  );
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteModerationRepository(
      ref.watch(apiClientProvider),
      ref.watch(peopleDirectoryProvider),
      currentUserId: () =>
          ref.read(authControllerProvider).valueOrNull?.accountId,
    );
  }
  return FakeModerationRepository(
    currentUserId: () =>
        ref.read(authControllerProvider).valueOrNull?.accountId,
  );
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteActivityRepository(ref.watch(apiClientProvider));
  }
  return FakeActivityRepository();
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteLearningRepository(ref.watch(apiClientProvider));
  }
  return FakeLearningRepository();
});

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemoteMeetingRepository(ref.watch(apiClientProvider));
  }
  final communities = ref.read(communityRepositoryProvider);
  return FakeMeetingRepository(communityById: communities.getCommunityById);
});

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  if (ApiConfig.useRemote) {
    return RemotePrivacyRepository(ref.watch(apiClientProvider));
  }
  return FakePrivacyRepository();
});
