import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/message_input_bar.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/messaging_repository.dart';
import '../domain/message.dart';
import '../domain/thread.dart';
import 'providers/messaging_providers.dart';
import '../../../core/theme/app_gradients.dart';

String _timeLabel(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

/// Screen 10: Conversation.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Opening a conversation marks it read.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repository = ref.read(threadRepositoryProvider);
      await repository.markRead(widget.threadId);
      if (!mounted) return; // never use ref after dispose
      ref.invalidate(threadsProvider);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _lastMessageCount = 0;

  void _scrollToBottom() {
    // Offstage (e.g. under a deep-linked report page) the list has no
    // size yet, so there is nothing to scroll.
    if (!mounted ||
        !_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() {});
    await ref.read(threadMessagesProvider(widget.threadId).notifier).send(text);
  }

  /// The under-18 limit, decided by the repository.
  bool _restrictedWith(Thread? thread) {
    ref.watch(messagingRestrictedProvider); // rebuild when it changes
    return thread != null &&
        !ref.read(threadRepositoryProvider).canMessage(thread.participant);
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(threadByIdProvider(widget.threadId));
    final messagesAsync = ref.watch(threadMessagesProvider(widget.threadId));
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            threadAsync.when(
              loading: () => const SizedBox(height: 80),
              error: (error, stackTrace) => const SizedBox(height: 80),
              data: (thread) => thread == null
                  ? const SizedBox(height: 80)
                  : _ConversationTopBar(
                      thread: thread,
                      threadId: widget.threadId,
                    ),
            ),
            const OfflineBanner(),
            if (threadAsync.hasValue && threadAsync.value == null)
              const Expanded(
                child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Conversation not available',
                  body: 'This conversation no longer exists or the person was blocked.',
                ),
              )
            else
              Expanded(
                child: messagesAsync.when(
                  loading: () =>
                      const Skeleton(showHeader: false, cardCount: 3),
                  error: (error, stackTrace) => ErrorView(
                    title: 'Could not load this conversation',
                    onRetry: () =>
                        ref.invalidate(threadMessagesProvider(widget.threadId)),
                  ),
                  data: (messages) {
                    if (messages.length > _lastMessageCount) {
                      _lastMessageCount = messages.length;
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom(),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final showDaySeparator =
                            index == 0 ||
                            formatDayLabel(messages[index - 1].sentAt) !=
                                formatDayLabel(message.sentAt);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDaySeparator)
                              _DaySeparator(
                                label: formatDayLabel(message.sentAt),
                              ),
                            _MessageBubble(
                              message: message,
                              onRetry: () => ref
                                  .read(
                                    threadMessagesProvider(widget.threadId)
                                        .notifier,
                                  )
                                  .retry(message.id),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            if (!(threadAsync.hasValue && threadAsync.value == null))
              if (_restrictedWith(threadAsync.valueOrNull))
                const _RestrictedBar()
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  // Offline: visible but inactive, like every other write.
                  child: MessageInputBar(
                    controller: _textController,
                    onSend: _send,
                    hintText: online ? 'Write a message' : 'You are offline',
                    enabled: online,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTopBar extends StatelessWidget {
  const _ConversationTopBar({required this.thread, required this.threadId});

  final Thread thread;
  final String threadId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.brand),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/messages'),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: 'View ${thread.participant.name}\'s profile',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/members/${thread.participant.id}'),
              child: AvatarWithPresence(
                initials: thread.participant.initials,
                size: 44,
                online: thread.participant.online,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  thread.participant.name,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${thread.roleLabel} · ${thread.participant.online ? 'Online now' : 'Offline'}',
                  style: AppTextStyles.body.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.flag_outlined,
            semanticLabel: 'Report',
            onPressed: () => context.push('/messages/$threadId/report'),
          ),
        ],
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: AppTextStyles.chip),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onRetry});

  final Message message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final failed = message.status == MessageStatus.failed;
    final bubble = Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? null : AppColors.white,
              gradient: AppGradients.when(mine),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 4),
                bottomRight: Radius.circular(mine ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 16, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  switch (message.status) {
                    MessageStatus.sending => 'Sending…',
                    MessageStatus.failed => 'Not sent · Tap to retry',
                    MessageStatus.sent => _timeLabel(message.sentAt),
                  },
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: AppColors.inkDeemphasized80,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!failed) return bubble;
    return Semantics(
      button: true,
      label: 'Message not sent. Tap to retry',
      child: GestureDetector(onTap: onRetry, child: bubble),
    );
  }
}

class _RestrictedBar extends StatelessWidget {
  const _RestrictedBar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: AppColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                MessagingRestricted.message,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
