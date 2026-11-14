import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../community/domain/person.dart';
import '../../data/messaging_repository.dart';
import '../providers/messaging_providers.dart';

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
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
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
        onTap: () async {
          final thread = await ref
              .read(threadRepositoryProvider)
              .openOrCreateThread(person, person.role.label);
          ref.invalidate(threadsProvider);
          if (!context.mounted) return;
          unawaited(context.push('/messages/${thread.id}'));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.mail_outline_rounded,
            color: AppColors.ink,
            size: 20,
          ),
        ),
      ),
    );
  }
}
