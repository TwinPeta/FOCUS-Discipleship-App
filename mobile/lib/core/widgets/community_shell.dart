import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/domain/user_role.dart';
import '../../features/community/presentation/providers/community_providers.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../theme/app_colors.dart';
import 'community_header_chrome.dart';
import 'community_sections.dart';
import 'round_icon_button.dart';
import 'states/offline_banner.dart';
import 'states/error_view.dart';
import 'states/skeleton.dart';
import 'app_bottom_nav.dart';

/// The amber header (name, section, Search, "⋯" sections menu) wrapping
/// every `/community/:id/*` tab screen.
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
      bottomNavigationBar: const AppBottomNav(current: AppTab.communities),
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
                  sectionLabel:
                      communityTabSections[navigationShell.currentIndex].label,
                  menuItems: communityMenuItems(
                    context,
                    communityId: communityId,
                    activePath:
                        communityTabSections[navigationShell.currentIndex].path,
                    goTab: (index) => navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                  ),
                  extraAction: isSuperMentor
                      ? RoundIconButton(
                          icon: Icons.tune_rounded,
                          semanticLabel: 'Manage community',
                          onPressed: () =>
                              context.push('/community/$communityId/manage'),
                        )
                      : null,
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
