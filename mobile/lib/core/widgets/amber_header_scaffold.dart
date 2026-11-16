import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../router/navigation.dart';
import 'round_icon_button.dart';

/// Amber header with 28px bottom corners, a plain back button, a title and
/// optional subtitle, a body slot and an optional pinned bottom action area.
/// Used by screens 9, 11, 15, 17, 19 and 20.
class AmberHeaderScaffold extends StatelessWidget {
  const AmberHeaderScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.headerAction,
    this.headerExtra,
    required this.body,
    this.bottomBar,
    this.onBack,
    this.backFallback = '/communities',
  });

  final String title;
  final String? subtitle;

  /// Overrides [subtitle] when rich formatting (e.g. a bold name) is needed.
  final Widget? subtitleWidget;

  /// Rendered at the end of the back-button row (e.g. the Messages inbox's
  /// "new message" button).
  final Widget? headerAction;
  final Widget? headerExtra;
  final Widget body;
  final Widget? bottomBar;
  final VoidCallback? onBack;

  /// Where Back goes when there is nothing to pop (deep link): the
  /// screen's logical parent.
  final String backFallback;

  @override
  Widget build(BuildContext context) {
    // While the keyboard is up the header shrinks to the back row and a
    // one-line title, so the field being typed in is never squeezed out.
    final compact = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadii.headerBottom),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  compact ? 8 : 16,
                  16,
                  compact ? 10 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: 'Back',
                          onPressed:
                              onBack ?? () => popOr(context, backFallback),
                        ),
                        if (headerAction != null) ...[
                          const Spacer(),
                          headerAction!,
                        ],
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 16),
                    Text(
                      title,
                      style: AppTextStyles.amberHeaderTitle,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (compact)
                      const SizedBox.shrink()
                    else if (subtitleWidget != null) ...[
                      const SizedBox(height: 6),
                      subtitleWidget!,
                    ] else if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle!, style: AppTextStyles.amberHeaderSubtitle),
                    ],
                    if (headerExtra != null && !compact) ...[
                      const SizedBox(height: 14),
                      headerExtra!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
          if (bottomBar != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.cream, width: 1),
                ),
              ),
              child: SafeArea(top: false, child: bottomBar!),
            ),
        ],
      ),
    );
  }
}
