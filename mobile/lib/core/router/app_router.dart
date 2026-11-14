import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/activity/presentation/my_activity_screen.dart';
import '../../features/auth/presentation/charter_screen.dart';
import '../../features/auth/presentation/consent_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/guardian_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/secure_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/community/presentation/communities_hub_screen.dart';
import '../../features/community/presentation/community_detail_screen.dart';
import '../../features/community/presentation/info_members_screen.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../../features/community/presentation/request_result_screens.dart';
import '../../features/feed/domain/post.dart';
import '../../features/feed/presentation/community_feed_screen.dart';
import '../../features/feed/presentation/composer_screen.dart';
import '../../features/feed/presentation/general_feed_screen.dart';
import '../../features/landing/presentation/landing_screen.dart';
import '../../features/learning/presentation/badge_earned_screen.dart';
import '../../features/learning/presentation/devotional_screen.dart';
import '../../features/learning/presentation/document_screen.dart';
import '../../features/learning/presentation/quiz_result_screen.dart';
import '../../features/learning/presentation/quiz_screen.dart';
import '../../features/learning/presentation/video_screen.dart';
import '../../features/learning/presentation/widgets/viewer_parts.dart';
import '../../features/messaging/presentation/conversation_screen.dart';
import '../../features/messaging/presentation/messages_inbox_screen.dart';
import '../../features/messaging/presentation/report_sent_screen.dart';
import '../../features/messaging/presentation/report_user_screen.dart';
import '../../features/pathways/presentation/pathway_steps_screen.dart';
import '../../features/pathways/presentation/pathways_screen.dart';
import '../../features/prayer/presentation/new_prayer_request_screen.dart';
import '../../features/prayer/presentation/prayer_wall_screen.dart';
import '../../features/profile/presentation/join_form_screen.dart';
import '../../features/profile/presentation/my_profile_screen.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../features/resources/presentation/resources_screen.dart';
import '../../features/testimony/presentation/share_testimony_screen.dart';
import '../../features/testimony/presentation/testimonies_screen.dart';
import '../debug/debug_scenarios_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/community_shell.dart';
import '../widgets/placeholder_screen.dart';
import '../widgets/states/error_view.dart';
import '../widgets/states/skeleton.dart';
import 'placeholder_routes.dart';
import 'route_guards.dart';

/// The app router. Built inside Riverpod so the guard chain
/// ([runGuards]) can read profile and membership state, and re-runs
/// whenever either changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(profileControllerProvider, (_, _) => refresh.value++);
  ref.listen(membershipProvider, (_, _) => refresh.value++);
  ref.listen(signUpControllerProvider, (_, _) => refresh.value++);
  ref.listen(currentRoleProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) => runGuards(
      GuardContext(
        location: state.uri,
        profile: ref.read(profileControllerProvider),
        membership: ref.read(membershipProvider),
        session: ref.read(authControllerProvider),
        signUp: ref.read(signUpControllerProvider),
        role: ref.read(currentRoleProvider),
      ),
    ),
    errorBuilder: (context, state) => const ErrorScreen(),
    routes: appRoutes,
  );
  ref.onDispose(router.dispose);
  return router;
});

String _id(GoRouterState state, [String name = 'id']) =>
    state.pathParameters[name]!;

/// The full route table (exposed for router tests). Placeholder routes come
/// first so `/messages/new` wins over `/messages/:threadId`.
final List<RouteBase> appRoutes = [
  GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
  GoRoute(
    path: '/loading',
    builder: (context, state) =>
        const Scaffold(backgroundColor: AppColors.page, body: Skeleton()),
  ),
  GoRoute(
    path: '/join',
    builder: (context, state) => const JoinFormScreen(),
    routes: [
      GoRoute(
        path: 'password',
        builder: (context, state) => const SecurePasswordScreen(),
      ),
      GoRoute(
        path: 'verify',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: 'consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: 'guardian',
        builder: (context, state) => const GuardianScreen(),
      ),
    ],
  ),
  GoRoute(path: '/login', builder: (context, state) => const SignInScreen()),
  GoRoute(
    path: '/forgot-password',
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(path: '/charter', builder: (context, state) => const CharterScreen()),
  for (final p in placeholderRoutes)
    GoRoute(
      path: p.path,
      builder: (context, state) =>
          PlaceholderScreen(owner: p.owner, title: p.title),
    ),
  if (kDebugMode)
    GoRoute(
      path: '/debug',
      builder: (context, state) => const DebugScenariosScreen(),
    ),
  GoRoute(
    path: '/request/approved',
    builder: (context, state) => const RequestApprovedScreen(),
  ),
  GoRoute(
    path: '/request/declined',
    builder: (context, state) => const RequestDeclinedScreen(),
  ),
  GoRoute(
    path: '/profile',
    builder: (context, state) => const MyProfileScreen(),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => JoinFormScreen(
            existingProfile: ref.watch(currentProfileProvider),
          ),
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/communities',
    builder: (context, state) => const CommunitiesHubScreen(),
  ),
  GoRoute(
    path: '/communities/:id',
    builder: (context, state) => CommunityDetailScreen(communityId: _id(state)),
  ),
  GoRoute(
    path: '/community/:id/compose',
    builder: (context, state) =>
        ComposerScreen(communityId: _id(state), scope: PostScope.specific),
  ),
  GoRoute(
    path: '/community/:id/prayer/new',
    builder: (context, state) =>
        NewPrayerRequestScreen(communityId: _id(state)),
  ),
  GoRoute(
    path: '/community/:id/testimonies/new',
    builder: (context, state) => ShareTestimonyScreen(communityId: _id(state)),
  ),
  GoRoute(
    path: '/community/:id/pathways/:pathwayId',
    builder: (context, state) => PathwayStepsScreen(
      communityId: _id(state),
      pathwayId: _id(state, 'pathwayId'),
    ),
  ),
  GoRoute(
    path: '/community/:id',
    // Only the bare path redirects; tab sub-routes pass through.
    redirect: (context, state) => state.uri.path == '/community/${_id(state)}'
        ? '/community/${_id(state)}/feed'
        : null,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => CommunityShell(
          communityId: _id(state),
          navigationShell: navigationShell,
        ),
        branches: [
          for (final tab in _communityTabs)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (context, state) => tab.build(_id(state)),
                ),
              ],
            ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/general-feed',
    builder: (context, state) => const GeneralFeedScreen(),
    routes: [
      GoRoute(
        path: 'compose',
        builder: (context, state) =>
            const ComposerScreen(scope: PostScope.general),
      ),
    ],
  ),
  GoRoute(
    path: '/messages',
    builder: (context, state) => const MessagesInboxScreen(),
    routes: [
      GoRoute(
        path: ':threadId',
        builder: (context, state) =>
            ConversationScreen(threadId: _id(state, 'threadId')),
        routes: [
          GoRoute(
            path: 'report',
            builder: (context, state) =>
                ReportUserScreen(threadId: _id(state, 'threadId')),
            routes: [
              GoRoute(
                path: 'sent',
                builder: (context, state) =>
                    ReportSentScreen(threadId: _id(state, 'threadId')),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/activity',
    builder: (context, state) => const MyActivityScreen(),
  ),
  // Learning viewers (33-38). `?pathway=&community=` says where they were
  // opened from (see `learningRoute`).
  GoRoute(
    path: '/resources/video/:id',
    builder: (context, state) =>
        VideoScreen(id: _id(state), origin: originOf(state)),
  ),
  GoRoute(
    path: '/devotional/:id',
    builder: (context, state) =>
        DevotionalScreen(id: _id(state), origin: originOf(state)),
  ),
  GoRoute(
    path: '/quiz/:id',
    builder: (context, state) =>
        QuizScreen(id: _id(state), origin: originOf(state)),
    routes: [
      GoRoute(
        path: 'result',
        builder: (context, state) =>
            QuizResultScreen(id: _id(state), origin: originOf(state)),
      ),
      GoRoute(
        path: 'review',
        builder: (context, state) =>
            QuizScreen(id: _id(state), origin: originOf(state), review: true),
      ),
    ],
  ),
  GoRoute(
    path: '/document/:id',
    builder: (context, state) =>
        DocumentScreen(id: _id(state), origin: originOf(state)),
  ),
  GoRoute(
    path: '/badge/:id/earned',
    builder: (context, state) => BadgeEarnedScreen(badgeId: _id(state)),
  ),
];

class _Tab {
  const _Tab(this.path, this.build);
  final String path;
  final Widget Function(String communityId) build;
}

final _communityTabs = <_Tab>[
  _Tab('feed', (id) => CommunityFeedScreen(communityId: id)),
  _Tab('prayer', (id) => PrayerWallScreen(communityId: id)),
  _Tab('testimonies', (id) => TestimoniesScreen(communityId: id)),
  _Tab('pathways', (id) => PathwaysScreen(communityId: id)),
  _Tab('resources', (id) => ResourcesScreen(communityId: id)),
  _Tab('info', (id) => InfoMembersScreen(communityId: id)),
];
