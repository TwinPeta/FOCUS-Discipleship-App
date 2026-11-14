import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/presentation/providers/community_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/online_count.dart';
import 'community_header_chrome.dart';
import 'community_tab_bar.dart';

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

    return Scaffold(
      backgroundColor: AppColors.page,
      body: communityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Could not load this community.',
            style: AppTextStyles.body,
          ),
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
                  onSelectGeneral: () => context.push('/general-feed'),
                  onSelectSpecific: () {},
                  tabBar: CommunityTabBar(
                    selectedIndex: navigationShell.currentIndex,
                    onTap: (index) => navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                  ),
                ),
                Expanded(child: navigationShell),
              ],
            ),
          );
        },
      ),
    );
  }
}
