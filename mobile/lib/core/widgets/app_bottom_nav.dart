import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/domain/membership.dart';
import '../../features/create/presentation/create_menu_sheet.dart';
import '../../features/messaging/presentation/providers/messaging_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../push/app_icon_badge.dart';
import 'count_badge.dart';
import '../router/navigation.dart';

/// The four top-level destinations.
enum AppTab { home, communities, messages, profile }

const _navHeight = 64.0;
const _createSize = 52.0;

/// Largest text scale for tab labels inside the fixed-height bar.
const _maxLabelScale = 1.3;

/// The approved specific community's id, or null when the user has none.
String? approvedCommunityId(Membership m) =>
    m.status == MembershipStatus.approved ? m.communityId : null;

/// Bottom navigation on the top-level screens (roadmap A1.1):
/// Home (General campus feed) | Communities (the hub, as in the design) |
/// Messages | Profile, with a centre Create button
/// that opens the Create menu. The label shows on the selected tab only.
/// Uses `go`, so switching tabs never grows the back stack.
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    this.handlesBack = true,
  });

  final AppTab current;

  /// False on screens with their own Back arrow (community pages,
  /// Messages): the phone's Back then does what that arrow does.
  final bool handlesBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      // Phone Back on a main tab goes Home; on Home the app closes.
      SystemBack(
        onBack: current == AppTab.home || !handlesBack
            ? null
            : () => context.go('/general-feed'),
        child: _bar(context, ref),
      );

  Widget _bar(BuildContext context, WidgetRef ref) {
    void select(AppTab tab) {
      if (tab == current) return;
      context.go(switch (tab) {
        AppTab.home => '/general-feed',
        AppTab.communities => '/communities',
        AppTab.messages => '/messages',
        AppTab.profile => '/profile',
      });
    }

    Widget tab(
      AppTab t,
      IconData icon,
      IconData selectedIcon,
      String label,
      String tooltip, {
      bool showLabel = true,
      int badge = 0,
    }) => Expanded(
      child: _NavTab(
        icon: icon,
        selectedIcon: selectedIcon,
        label: label,
        tooltip: tooltip,
        showLabel: showLabel,
        badge: badge,
        selected: t == current,
        onTap: () => select(t),
      ),
    );
    final unreadMessages = ref.watch(unreadMessageCountProvider);
    // The phone's home-screen icon shows the same total (like WhatsApp).
    // Skipped when the number has not changed.
    updateAppIconBadge(unreadMessages);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.cream)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _navHeight,
          child: Row(
            children: [
              tab(
                AppTab.home,
                Icons.home_outlined,
                Icons.home_rounded,
                'Home',
                'Home: campus feed',
              ),
              tab(
                AppTab.communities,
                Icons.groups_outlined,
                Icons.groups_rounded,
                'Communities',
                'Your community',
                // Icon only (product decision); screen readers still hear it.
                showLabel: false,
              ),
              const _CreateButton(),
              tab(
                AppTab.messages,
                Icons.chat_outlined,
                Icons.chat_rounded,
                'Messages',
                'Messages',
                badge: unreadMessages,
              ),
              tab(
                AppTab.profile,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profile',
                'My profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    this.showLabel = true,
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  /// When false the tab never shows its text, only the icon.
  final bool showLabel;

  /// Unread count shown on the icon (0: none).
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge unread' : label,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 10 : 8,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.honey : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        color: AppColors.ink,
                      ),
                      if (badge > 0)
                        Positioned(
                          top: -8,
                          right: -12,
                          child: CountBadge(count: badge),
                        ),
                    ],
                  ),
                  if (selected && showLabel)
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // The bar has a fixed height; cap the label's growth
                      // (screen readers still read it; icons carry meaning).
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: _maxLabelScale),
                      style: AppTextStyles.chip.copyWith(
                        fontSize: 11,
                        color: AppColors.ink,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The prominent centre button that opens the Create menu.
class _CreateButton extends StatelessWidget {
  const _CreateButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Semantics(
        button: true,
        label: 'Create',
        excludeSemantics: true,
        child: Tooltip(
          message: 'Create',
          child: Material(
            color: AppColors.amberDark,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => unawaited(showCreateMenu(context)),
              child: SizedBox(
                width: _createSize,
                height: _createSize,
                child: Icon(Icons.add_rounded, size: 30, color: AppColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
