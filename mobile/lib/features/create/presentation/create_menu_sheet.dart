import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/bottom_sheet_scaffold.dart';

const _tileSize = 44.0;

/// Opens the Create menu (design screen 66) from the bottom bar's centre
/// button.
Future<void> showCreateMenu(BuildContext context) =>
    showAppBottomSheet<void>(context, builder: (_) => const CreateMenuSheet());

/// The Create menu: ask or answer a question, write a post, prayer request
/// and share a story. Each opens the one Create screen (`/create`), where
/// the student picks General or their community.
class CreateMenuSheet extends ConsumerWidget {
  const CreateMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);

    void open(String route) {
      Navigator.of(context).pop();
      unawaited(router.push(route));
    }

    return BottomSheetScaffold(
      title: 'Create',
      children: [
        CreateMenuRow(
          icon: Icons.help_outline_rounded,
          title: 'Ask a question',
          subtitle: 'Get answers from the community',
          onTap: () => open('/create?type=question'),
        ),
        CreateMenuRow(
          icon: Icons.question_answer_outlined,
          title: 'Answer a question',
          subtitle: 'Help someone in your community',
          onTap: () => open('/questions'),
        ),
        CreateMenuRow(
          icon: Icons.edit_note_rounded,
          title: 'Write a post',
          subtitle: 'Share text and a photo',
          onTap: () => open('/create?type=post'),
        ),
        CreateMenuRow(
          icon: Icons.volunteer_activism_outlined,
          title: 'Prayer request',
          subtitle: 'Ask the community to pray',
          onTap: () => open('/create?type=prayer'),
        ),
        CreateMenuRow(
          icon: Icons.auto_stories_outlined,
          title: 'Share a story',
          subtitle: 'A testimony, reviewed before it is published',
          onTap: () => open('/create?type=story'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.ink,
          ),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// One Create menu row: icon tile, title, subtitle. A row without [onTap] is
/// shown faded with [disabledNote] explaining why.
class CreateMenuRow extends StatelessWidget {
  const CreateMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.disabledNote,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? disabledNote;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final note = enabled ? null : disabledNote;
    return Semantics(
      button: true,
      enabled: enabled,
      label: [title, subtitle, ?note].join(', '),
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: _tileSize,
                    height: _tileSize,
                    decoration: BoxDecoration(
                      color: AppColors.honey,
                      borderRadius: BorderRadius.circular(AppRadii.tile),
                    ),
                    child: Icon(icon, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12.5,
                            color: AppColors.inkDeemphasized80,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(width: 8),
                    Text(note, style: AppTextStyles.chip),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
