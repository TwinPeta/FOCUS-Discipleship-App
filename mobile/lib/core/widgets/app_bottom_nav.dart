import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/domain/membership.dart';
import '../../features/create/presentation/create_menu_sheet.dart';
import '../../features/messaging/presentation/providers/messaging_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_text_styles.dart';
import '../push/app_icon_badge.dart';
import 'count_badge.dart';
import '../router/navigation.dart';

/// The four top-level destinations.
enum AppTab { home, communities, messages, profile }

/// Height of the white bar (above the safe-area inset).
const _barHeight = 64.0;

/// The selected destination's raised white circle.
const _circleSize = 56.0;

/// Gap between the circle and the notch cut into the bar around it.
const _notchGap = 6.0;

/// Room above the bar for the half of the circle that rises out of it.
const _rise = _circleSize / 2 + 6;

const _createSize = 52.0;

/// Largest text scale for tab labels inside the fixed-height bar.
const _maxLabelScale = 1.3;

/// The approved specific community's id, or null when the user has none.
String? approvedCommunityId(Membership m) =>
    m.status == MembershipStatus.approved ? m.communityId : null;

/// One destination of the bar.
class _Dest {
  const _Dest(
    this.tab,
    this.icon,
    this.selectedIcon,
    this.label,
    this.tooltip, {
    this.showLabel = true,
  });

  final AppTab tab;

  /// Outline when not selected, filled when selected.
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;

  /// When false the tab never shows its text, only the icon.
  final bool showLabel;
}

const _destinations = [
  _Dest(
    AppTab.home,
    Icons.home_outlined,
    Icons.home_rounded,
    'Home',
    'Home: campus feed',
  ),
  _Dest(
    AppTab.communities,
    Icons.groups_outlined,
    Icons.groups_rounded,
    'Caregroups',
    'Your caregroup',
    // Icon only (product decision); screen readers still hear it.
    showLabel: false,
  ),
  _Dest(
    AppTab.messages,
    Icons.chat_bubble_outline_rounded,
    Icons.chat_bubble_rounded,
    'Messages',
    'Messages',
  ),
  _Dest(
    AppTab.profile,
    Icons.person_outline_rounded,
    Icons.person_rounded,
    'Profile',
    'My profile',
  ),
];

/// Bottom navigation on the top-level screens (`nav/re-design.jpg`,
/// `nav/nav_guide.md`): Home | Caregroups | Create | Messages | Profile in
/// five equal columns. The bar is one seamless white surface (no top
/// rule); the selected destination rises out of it as a white circle with
/// a filled blue icon, sitting in a smooth notch cut into the bar, with its
/// label below. Other destinations show outline icons. The centre Create
/// button is an action (opens the Create menu), never the selected tab.
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

    final unreadMessages = ref.watch(unreadMessageCountProvider);
    // The phone's home-screen icon shows the same total (like WhatsApp).
    // Skipped when the number has not changed.
    updateAppIconBadge(unreadMessages);
    int badgeOf(AppTab t) => t == AppTab.messages ? unreadMessages : 0;

    // Column of each destination: the Create action takes the middle one.
    int slotOf(AppTab t) => switch (t) {
      AppTab.home => 0,
      AppTab.communities => 1,
      AppTab.messages => 3,
      AppTab.profile => 4,
    };
    final selected = _destinations.firstWhere((d) => d.tab == current);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      height: _rise + _barHeight + bottomInset,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / 5;
          final centerX = slotWidth * (slotOf(current) + 0.5);
          Widget slot(_Dest d) => Expanded(
            child: _NavTab(
              dest: d,
              selected: d.tab == current,
              badge: badgeOf(d.tab),
              onTap: () => select(d.tab),
            ),
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The bar: one white surface, notched under the selected tab.
              Positioned.fill(
                top: _rise,
                child: CustomPaint(
                  painter: _NotchedBarPainter(
                    notchCenterX: centerX,
                    color: AppColors.white,
                    shadow: AppColors.ink.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                top: _rise,
                left: 0,
                right: 0,
                height: _barHeight,
                child: Row(
                  children: [
                    slot(_destinations[0]),
                    slot(_destinations[1]),
                    const Expanded(child: Center(child: _CreateButton())),
                    slot(_destinations[2]),
                    slot(_destinations[3]),
                  ],
                ),
              ),
              // The selected destination's raised circle.
              Positioned(
                left: centerX - _circleSize / 2,
                top: _rise - _circleSize / 2,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Transform.translate(
                    offset: Offset(0, (1 - t) * 14),
                    child: child,
                  ),
                  child: _RaisedCircle(
                    dest: selected,
                    badge: badgeOf(selected.tab),
                    onTap: () => select(selected.tab),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The white bar with a smooth circular notch around the raised circle,
/// and a soft shadow along its top edge instead of a separating line.
class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter({
    required this.notchCenterX,
    required this.color,
    required this.shadow,
  });

  final double notchCenterX;
  final Color color;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const CircularNotchedRectangle().getOuterPath(
      Offset.zero & size,
      Rect.fromCircle(
        center: Offset(notchCenterX, 0),
        radius: _circleSize / 2 + _notchGap,
      ),
    );
    canvas
      ..drawShadow(path, shadow, 6, false)
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.notchCenterX != notchCenterX ||
      old.color != color ||
      old.shadow != shadow;
}

/// A destination's place in the bar. Not selected: its outline icon.
/// Selected: the raised circle sits above, and the label shows here.
class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.dest,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  /// Unread count shown on the icon (0: none).
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '${dest.label}, $badge unread' : dest.label,
      excludeSemantics: true,
      child: Tooltip(
        message: dest.tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.expand(
            child: selected
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: dest.showLabel
                          ? Text(
                              dest.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              // The bar has a fixed height; cap the label's
                              // growth (screen readers still read it).
                              textScaler: MediaQuery.textScalerOf(
                                context,
                              ).clamp(maxScaleFactor: _maxLabelScale),
                              style: AppTextStyles.chip.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  )
                : Center(
                    child: _IconWithBadge(
                      icon: dest.icon,
                      color: AppColors.muted,
                      badge: badge,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The selected destination: a white circle with its filled icon in blue.
class _RaisedCircle extends StatelessWidget {
  const _RaisedCircle({required this.dest, required this.onTap, this.badge = 0});

  final _Dest dest;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    // The tab below already announces it (selected) to screen readers.
    return ExcludeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _circleSize,
          height: _circleSize,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                // Soft, close glow: a strong offset shadow shows as a grey
                // crescent in the notch gap.
                color: AppColors.ink.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _IconWithBadge(
            icon: dest.selectedIcon,
            color: AppColors.primary,
            size: 27,
            badge: badge,
          ),
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    this.size = 25,
    this.badge = 0,
  });

  final IconData icon;
  final Color color;
  final double size;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: size),
        if (badge > 0)
          Positioned(top: -8, right: -12, child: CountBadge(count: badge)),
      ],
    );
  }
}

/// The prominent centre button that opens the Create menu.
class _CreateButton extends StatelessWidget {
  const _CreateButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Create',
        // Design: a raised gold-gradient rounded square.
        // Solid fill under the gradient: a see-through Material paints its
        // shadow as a dark ring around the button.
        child: Material(
          color: AppColors.amberDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
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
