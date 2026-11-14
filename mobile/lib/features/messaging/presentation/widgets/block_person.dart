import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/error_snack.dart';
import '../../../community/domain/person.dart';
import '../providers/moderation_providers.dart';

/// Blocks [person] after a confirmation, then shows "Blocked" with Undo.
/// Returns true when the block went through.
Future<bool> confirmAndBlock(
  BuildContext context,
  WidgetRef ref,
  Person person,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Block ${person.name}?',
    message:
        'They will not be able to message you, and you will not see their '
        'posts, comments or messages. You can unblock them in Settings.',
    confirmLabel: 'Block',
    destructive: true,
  );
  if (!confirmed || !context.mounted) return false;
  final actions = ref.read(moderationActionsProvider);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await actions.block(person.id);
  } catch (_) {
    if (context.mounted) showErrorSnack(context, 'Could not block. Try again.');
    return false;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${person.name} is blocked.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => actions.unblock(person.id).catchError((_) {}),
        ),
      ),
    );
  return true;
}
