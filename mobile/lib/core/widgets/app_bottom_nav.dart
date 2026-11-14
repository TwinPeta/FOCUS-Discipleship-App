import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/domain/membership.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../theme/app_colors.dart';

/// The three top-level destinations.
enum AppTab { home, community, profile }

const _navHeight = 64.0;

/// Bottom navigation on the top-level screens: Home (General campus feed),
/// Community (your specific community's feed, or the hub to find one) and
/// Profile. Uses `go`, so switching tabs never grows the back stack.
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, required this.current});

  final AppTab current;

  static String communityRoute(Membership m) =>
      m.status == MembershipStatus.approved && m.communityId != null
      ? '/community/${m.communityId}/feed'
      : '/communities';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership =
        ref.watch(membershipProvider).valueOrNull ?? Membership.empty;
    void select(int i) {
      final tab = AppTab.values[i];
      if (tab == current) return;
      context.go(switch (tab) {
        AppTab.home => '/general-feed',
        AppTab.community => communityRoute(membership),
        AppTab.profile => '/profile',
      });
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cream)),
      ),
      child: NavigationBar(
        height: _navHeight,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.honey,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: current.index,
        onDestinationSelected: select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.ink),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.ink),
            label: 'Home',
            tooltip: 'Home: campus feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: AppColors.ink),
            selectedIcon: Icon(Icons.groups_rounded, color: AppColors.ink),
            label: 'Community',
            tooltip: 'Your community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: AppColors.ink),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.ink),
            label: 'Profile',
            tooltip: 'My profile',
          ),
        ],
      ),
    );
  }
}
