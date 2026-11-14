import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const communityShellTabs = [
  'Feed',
  'Prayer',
  'Testimonies',
  'Pathways',
  'Resources',
  'Info & members',
];

/// The scrollable tab bar inside [CommunityShell]'s header. Auto-scrolls the
/// selected tab into view whenever [selectedIndex] changes.
class CommunityTabBar extends StatefulWidget {
  const CommunityTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  State<CommunityTabBar> createState() => _CommunityTabBarState();
}

class _CommunityTabBarState extends State<CommunityTabBar> {
  final _scrollController = ScrollController();
  final _keys = List.generate(communityShellTabs.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant CommunityTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    final renderContext = _keys[widget.selectedIndex].currentContext;
    if (renderContext != null) {
      Scrollable.ensureVisible(
        renderContext,
        duration: const Duration(milliseconds: 200),
        alignment: 0.5,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var i = 0; i < communityShellTabs.length; i++)
              _TabItem(
                key: _keys[i],
                label: communityShellTabs[i],
                selected: i == widget.selectedIndex,
                onTap: () => widget.onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.ink : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.chip.copyWith(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
