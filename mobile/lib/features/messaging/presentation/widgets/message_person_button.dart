import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_snack.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../community/domain/person.dart';
import '../../data/messaging_repository.dart';
import '../providers/messaging_providers.dart';
import '../../../../core/theme/app_gradients.dart';

/// Opens (or creates) the thread with [person] and shows it. [replace]
/// swaps the current page for the conversation (New message, screen 54).
/// The repository refuses blocked people and the under-18 limit; both end
/// in a snackbar instead of a thread.
Future<void> openConversation(
  BuildContext context,
  WidgetRef ref,
  Person person, {
  bool replace = false,
}) async {
  try {
    final thread = await ref
        .read(threadRepositoryProvider)
        .openOrCreateThread(person, person.role.label);
    ref.invalidate(threadsProvider);
    if (!context.mounted) return;
    final route = '/messages/${thread.id}';
    if (replace) {
      context.pushReplacement(route);
    } else {
      unawaited(context.push(route));
    }
  } on MessagingRestricted {
    if (context.mounted) showErrorSnack(context, MessagingRestricted.message);
  } on PersonBlocked {
    if (context.mounted) {
      showErrorSnack(context, 'Unblock ${person.name} to send a message.');
    }
  } catch (_) {
    if (context.mounted) showErrorSnack(context);
  }
}

/// 44px amber "message" tile that opens (or creates) a thread with
/// [person]. Disabled, with the reason, when the under-18 limit applies.
/// Shared by Info & members (6) and Members to follow up (30).
class MessagePersonButton extends ConsumerWidget {
  const MessagePersonButton({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(messagingRestrictedProvider);
    if (!ref.read(threadRepositoryProvider).canMessage(person)) {
      // Under-18 limit: visible but disabled, with the reason.
      return Tooltip(
        message: MessagingRestricted.message,
        child: Semantics(
          button: true,
          enabled: false,
          label: 'Message ${person.name}. ${MessagingRestricted.message}',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.lock_clock_outlined,
              color: AppColors.placeholder,
              size: 20,
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Message ${person.name}',
      child: InkWell(
        onTap: () => openConversation(context, ref, person),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.mail_outline_rounded,
            color: AppColors.ink,
            size: 20,
          ),
        ),
      ),
    );
  }
}
