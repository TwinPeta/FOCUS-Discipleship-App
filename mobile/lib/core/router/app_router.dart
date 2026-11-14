import 'package:go_router/go_router.dart';

import '../../features/community/presentation/communities_hub_screen.dart';
import '../../features/community/presentation/community_detail_screen.dart';
import '../../features/community/presentation/info_members_screen.dart';
import '../../features/feed/domain/post.dart';
import '../../features/feed/presentation/community_feed_screen.dart';
import '../../features/feed/presentation/composer_screen.dart';
import '../../features/feed/presentation/general_feed_screen.dart';
import '../../features/activity/presentation/my_activity_screen.dart';
import '../../features/landing/presentation/landing_screen.dart';
import '../../features/messaging/presentation/conversation_screen.dart';
import '../../features/messaging/presentation/messages_inbox_screen.dart';
import '../../features/messaging/presentation/report_sent_screen.dart';
import '../../features/messaging/presentation/report_user_screen.dart';
import '../../features/pathways/presentation/pathway_steps_screen.dart';
import '../../features/pathways/presentation/pathways_screen.dart';
import '../../features/prayer/presentation/new_prayer_request_screen.dart';
import '../../features/prayer/presentation/prayer_wall_screen.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/profile/presentation/join_form_screen.dart';
import '../../features/profile/presentation/my_profile_screen.dart';
import '../../features/resources/presentation/resources_screen.dart';
import '../../features/testimony/presentation/share_testimony_screen.dart';
import '../../features/testimony/presentation/testimonies_screen.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/community_shell.dart';
import '../widgets/route_guards.dart';

/// Central route table (sections 3 and 5 of the next-15-screens brief).
/// Everything still out of scope routes to [ComingSoonScreen] so navigation
/// never dead-ends.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
    GoRoute(
      path: '/join',
      builder: (context, state) =>
          JoinFormScreen(existingProfile: state.extra as UserProfile?),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MyProfileScreen(),
    ),
    GoRoute(
      path: '/communities',
      builder: (context, state) => const CommunitiesHubScreen(),
    ),
    GoRoute(
      path: '/communities/:id',
      builder: (context, state) =>
          CommunityDetailScreen(communityId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/community/:id',
      redirect: (context, state) =>
          '/community/${state.pathParameters['id']}/feed',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            final communityId = state.pathParameters['id']!;
            return RequireApprovedMembership(
              communityId: communityId,
              child: CommunityShell(
                communityId: communityId,
                navigationShell: navigationShell,
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'feed',
                  builder: (context, state) => CommunityFeedScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'prayer',
                  builder: (context, state) => PrayerWallScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'testimonies',
                  builder: (context, state) => TestimoniesScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'pathways',
                  builder: (context, state) => PathwaysScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'resources',
                  builder: (context, state) => ResourcesScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'info',
                  builder: (context, state) => InfoMembersScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/community/:id/prayer/new',
      builder: (context, state) => RequireApprovedMembership(
        communityId: state.pathParameters['id']!,
        child: NewPrayerRequestScreen(communityId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/community/:id/testimonies/new',
      builder: (context, state) => RequireApprovedMembership(
        communityId: state.pathParameters['id']!,
        child: ShareTestimonyScreen(communityId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/community/:id/pathways/:pathwayId',
      builder: (context, state) => RequireApprovedMembership(
        communityId: state.pathParameters['id']!,
        child: PathwayStepsScreen(pathwayId: state.pathParameters['pathwayId']!),
      ),
    ),
    GoRoute(
      path: '/general-feed',
      builder: (context, state) =>
          const RequireProfile(child: GeneralFeedScreen()),
    ),
    GoRoute(
      path: '/compose',
      builder: (context, state) {
        final extra = state.extra;
        final communityId = extra is Map ? extra['communityId'] as String? : null;
        if (communityId == null) {
          return const ComingSoonScreen(title: 'New post');
        }
        final scope = state.uri.queryParameters['scope'] == 'general'
            ? PostScope.general
            : PostScope.specific;
        return RequireProfile(
          child: ComposerScreen(communityId: communityId, scope: scope),
        );
      },
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) =>
          const RequireProfile(child: MessagesInboxScreen()),
    ),
    GoRoute(
      path: '/messages/:threadId',
      builder: (context, state) => RequireProfile(
        child: ConversationScreen(threadId: state.pathParameters['threadId']!),
      ),
    ),
    GoRoute(
      path: '/messages/:threadId/report',
      builder: (context, state) => RequireProfile(
        child: ReportUserScreen(threadId: state.pathParameters['threadId']!),
      ),
    ),
    GoRoute(
      path: '/messages/:threadId/report/sent',
      builder: (context, state) => RequireProfile(
        child: ReportSentScreen(threadId: state.pathParameters['threadId']!),
      ),
    ),
    GoRoute(
      path: '/activity',
      builder: (context, state) =>
          const RequireProfile(child: MyActivityScreen()),
    ),
  ],
);
