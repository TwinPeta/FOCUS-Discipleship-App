import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/presentation/widgets/community_cover_painter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'round_icon_button.dart';
import 'scope_switch.dart';

/// Shared amber header chrome: back button, name panel with online count,
/// messages button, and the General/specific [ScopeSwitch] — all painted
/// over the screen-4 cover art. [CommunityShell] appends a tab bar below it;
/// [GeneralShell] does not.
class CommunityHeaderChrome extends StatelessWidget {
  const CommunityHeaderChrome({
    super.key,
    required this.title,
    required this.onlineCount,
    required this.generalSelected,
    required this.specificLabel,
    required this.onSelectGeneral,
    required this.onSelectSpecific,
    this.tabBar,
    this.onBack,
    this.extraAction,
  });

  final String title;
  final int onlineCount;
  final bool generalSelected;
  final String specificLabel;
  final VoidCallback onSelectGeneral;
  final VoidCallback onSelectSpecific;
  final Widget? tabBar;
  final VoidCallback? onBack;

  /// Role-only action shown before Messages (e.g. super-mentor Manage).
  final Widget? extraAction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: AppColors.honey,
              child: const RepaintBoundary(
                child: CustomPaint(
                  painter: CommunityCoverPainter(),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        Container(color: AppColors.amber.withValues(alpha: 0.55)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Back',
                    onPressed:
                        onBack ??
                        () => context.canPop()
                            ? context.pop()
                            : context.go('/communities'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '$onlineCount online now',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (extraAction != null) ...[
                    const SizedBox(width: 10),
                    extraAction!,
                  ],
                  const SizedBox(width: 10),
                  RoundIconButton(
                    icon: Icons.mail_outline_rounded,
                    semanticLabel: 'Messages',
                    onPressed: () => context.push('/messages'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ScopeSwitch(
                specificLabel: specificLabel,
                generalSelected: generalSelected,
                onSelectGeneral: onSelectGeneral,
                onSelectSpecific: onSelectSpecific,
              ),
              if (tabBar != null) ...[
                const SizedBox(height: 12),
                tabBar!,
              ] else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
