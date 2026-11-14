import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/domain/user_role.dart';
import '../../features/community/presentation/providers/community_providers.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../theme/app_colors.dart';
import '../utils/online_count.dart';
import 'community_header_chrome.dart';
import 'community_tab_bar.dart';
import 'round_icon_button.dart';
import 'states/offline_banner.dart';
import 'states/error_view.dart';
import 'states/skeleton.dart';

/// The amber header + 6-tab shell wrapping every `/community/:id/*` screen.
/// Pass a [StatefulNavigationShell] so switching tabs keeps this header
/// mounted and preserves each tab's own navigation stack.
class CommunityShell extends ConsumerWidget {
  const CommunityShell({
    super.key,
    required this.communityId,
    required this.navigationShell,
  });

  final String communityId;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(communityByIdProvider(communityId));
    final isSuperMentor =
        ref.watch(currentRoleProvider) == UserRole.superMentor;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: communityAsync.when(
        loading: () => const Skeleton(),
        error: (error, stackTrace) => ErrorScreen(
          onRetry: () => ref.invalidate(communityByIdProvider(communityId)),
        ),
        data: (community) {
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                CommunityHeaderChrome(
                  title: community.name,
                  onlineCount: estimateOnlineCount(community.id),
                  generalSelected: false,
                  specificLabel: community.name,
                  onSelectGeneral: () => context.go('/general-feed'),
                  onSelectSpecific: () {},
                  extraAction: isSuperMentor
                      ? RoundIconButton(
                          icon: Icons.tune_rounded,
                          semanticLabel: 'Manage community',
                          onPressed: () =>
                              context.push('/community/$communityId/manage'),
                        )
                      : null,
                  tabBar: CommunityTabBar(
                    selectedIndex: navigationShell.currentIndex,
                    onTap: (index) => navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                  ),
                ),
                const OfflineBanner(),
                Expanded(child: navigationShell),
              ],
            ),
          );
        },
      ),
    );
  }
}
