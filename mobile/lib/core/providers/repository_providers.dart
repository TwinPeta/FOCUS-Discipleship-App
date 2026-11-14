import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/community/data/community_repository.dart';
import '../../features/community/data/join_request_repository.dart';
import '../../features/community/data/membership_repository.dart';
import '../../features/feed/data/post_repository.dart';
import '../../features/learning/data/learning_repository.dart';
import '../../features/landing/data/stories_repository.dart';
import '../../features/activity/data/activity_repository.dart';
import '../../features/messaging/data/messaging_repository.dart';
import '../../features/messaging/data/moderation_repository.dart';
import '../../features/messaging/data/report_repository.dart';
import '../../features/moderation/data/moderation_queue_repository.dart';
import '../../features/moderation/data/suspension_repository.dart';
import '../../features/moderation/data/warning_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/pathways/data/pathway_repository.dart';
import '../../features/prayer/data/prayer_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/resources/data/resource_repository.dart';
import '../../features/testimony/data/testimony_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FakeAuthRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return FakeCommunityRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FakeNotificationRepository();
});

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return FakeMembershipRepository(
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  return FakeJoinRequestRepository(
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final warningRepositoryProvider = Provider<WarningRepository>((ref) {
  return FakeWarningRepository();
});

final suspensionRepositoryProvider = Provider<SuspensionRepository>((ref) {
  return FakeSuspensionRepository();
});

final moderationQueueRepositoryProvider = Provider<ModerationQueueRepository>(
  (ref) => FakeModerationQueueRepository(
    notifications: ref.read(notificationRepositoryProvider),
    warnings: ref.read(warningRepositoryProvider),
  ),
);

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final moderation = ref.read(moderationQueueRepositoryProvider);
  return FakePostRepository(isHidden: moderation.isHidden);
});

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return FakeStoriesRepository();
});

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return FakeResourceRepository();
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final moderation = ref.read(moderationQueueRepositoryProvider);
  return FakePrayerRepository(isHidden: moderation.isHidden);
});

final testimonyRepositoryProvider = Provider<TestimonyRepository>((ref) {
  final moderation = ref.read(moderationQueueRepositoryProvider);
  return FakeTestimonyRepository(isHidden: moderation.isHidden);
});

final pathwayRepositoryProvider = Provider<PathwayRepository>((ref) {
  return FakePathwayRepository();
});

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  // Read lazily so the store survives profile/guardian changes.
  return FakeMessagingRepository(
    isRestricted: () => ref.read(messagingRestrictedProvider),
  );
});

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ref.watch(messagingRepositoryProvider);
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return ref.watch(messagingRepositoryProvider);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return FakeReportRepository(
    moderation: ref.read(moderationQueueRepositoryProvider),
  );
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return FakeModerationRepository();
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return FakeActivityRepository();
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return FakeLearningRepository();
});
