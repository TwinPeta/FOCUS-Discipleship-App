import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/bottom_sheet_scaffold.dart';
import '../../../../core/widgets/error_snack.dart';
import '../../domain/community.dart';
import '../providers/membership_provider.dart';

/// Screen 29: Leave {community}? (bottom sheet over Info & members).
Future<void> showLeaveCommunitySheet(
  BuildContext context,
  Community community,
) {
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _LeaveCommunitySheet(community: community),
  );
}

class _LeaveCommunitySheet extends ConsumerStatefulWidget {
  const _LeaveCommunitySheet({required this.community});

  final Community community;

  @override
  ConsumerState<_LeaveCommunitySheet> createState() =>
      _LeaveCommunitySheetState();
}

class _LeaveCommunitySheetState extends ConsumerState<_LeaveCommunitySheet> {
  bool _leaving = false;

  static const _points = <(IconData, String)>[
    (
      Icons.lock_outline_rounded,
      'You lose access to its feed, prayer wall and resources.',
    ),
    (Icons.article_outlined, 'Your posts stay unless you delete them.'),
    (
      Icons.swap_horiz_rounded,
      'You can then request another specific community. You can be in only '
          'one.',
    ),
  ];

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    // Capture before the sheet (and this context) go away.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(membershipProvider.notifier).leave();
      if (!mounted) return;
      Navigator.of(context).pop();
      router.go('/communities');
      messenger.showSnackBar(
        SnackBar(content: Text('You left ${widget.community.name}.')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _leaving = false);
        showErrorSnack(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.community.name;
    return BottomSheetScaffold(
      title: 'Leave $name?',
      children: [
        for (final (icon, text) in _points)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: AppTextStyles.body)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        AppPrimaryButton(
          label: 'Stay in $name',
          onPressed: _leaving ? null : () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 48,
            minWidth: double.infinity,
          ),
          child: OutlinedButton(
            onPressed: _leaving ? null : _leave,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: _leaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Leave community',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }
}
