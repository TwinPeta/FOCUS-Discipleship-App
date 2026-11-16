import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/presentation/widgets/community_cover_painter.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_text_styles.dart';
import 'round_icon_button.dart';

/// One place in a community's "⋯" menu (General, Feed, Prayer wall, ...).
class SectionMenuItem {
  const SectionMenuItem({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.active = false,
    this.dividerBefore = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;

  /// The section on screen: highlighted in the menu.
  final bool active;

  /// A line above this item (e.g. between General and the community).
  final bool dividerBefore;
}

/// The amber community header: back, the community name with the section
/// you are in, then Search and "⋯" (every section, the active one
/// highlighted). Super-mentors also get [extraAction] (Manage). Painted
/// over the cover art.
class CommunityHeaderChrome extends StatelessWidget {
  const CommunityHeaderChrome({
    super.key,
    required this.title,
    required this.sectionLabel,
    required this.menuItems,
    this.onBack,
    this.extraAction,
  });

  final String title;

  /// Where you are, under the name (e.g. "Prayer wall").
  final String sectionLabel;
  final List<SectionMenuItem> menuItems;
  final VoidCallback? onBack;

  /// Role-only action shown before Search (e.g. super-mentor Manage).
  final Widget? extraAction;

  @override
  Widget build(BuildContext context) {
    // Clip: the cover art must not paint over the page below the header.
    return ClipRect(child: _content(context));
  }

  Widget _content(BuildContext context) {
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
        // Brand gradient over the cover art, translucent so the art shows.
        Container(
          decoration: BoxDecoration(
            gradient: AppGradients.brand.withOpacity(0.6),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
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
                child: Semantics(
                  header: true,
                  label: '$title, $sectionLabel',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Whole name: shrinks with large text.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.amberDark,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                sectionLabel,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
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
              ),
              if (extraAction != null) ...[
                const SizedBox(width: 8),
                extraAction!,
              ],
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.search_rounded,
                semanticLabel: 'Search',
                onPressed: () => context.push('/search'),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.more_horiz_rounded,
                semanticLabel: 'Sections',
                onPressed: () => showSectionMenu(context, title, menuItems),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The "⋯" sheet: every section; the one on screen is highlighted (gold
/// bar, tinted row, check) so you always know where you are.
Future<void> showSectionMenu(
  BuildContext context,
  String title,
  List<SectionMenuItem> items,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
              child: Text(title, style: AppTextStyles.sectionHeading),
            ),
            for (final item in items) ...[
              if (item.dividerBefore)
                Divider(height: 16, color: AppColors.cream),
              _SectionRow(
                item: item,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (!item.active) item.onSelected();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.item, required this.onTap});

  final SectionMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = item.active;
    return Semantics(
      button: true,
      selected: active,
      label: active ? '${item.label}, current' : item.label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: active ? AppColors.honey : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  // Active indicator bar.
                  Container(
                    width: 4,
                    height: 28,
                    margin: const EdgeInsets.only(left: 6, right: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.amberDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Icon(item.icon, size: 22, color: AppColors.ink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (active)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.check_rounded,
                        size: 20,
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
