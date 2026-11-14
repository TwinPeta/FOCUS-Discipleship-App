import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/initials.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/message_input_bar.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../learning/presentation/learning_providers.dart';
import '../../learning/presentation/widgets/viewer_parts.dart';
import '../domain/prayer_request.dart';
import '../domain/prayer_response.dart';
import 'providers/prayer_detail_providers.dart';
import 'providers/prayer_providers.dart';

const _avatarSize = 40.0;

/// "1 person prayed" / "8 people prayed".
String prayedLabel(int count) =>
    count == 1 ? '1 person prayed' : '$count people prayed';

/// Screen 52: Prayer request (`/prayer/:id`). An anonymous author stays
/// anonymous everywhere, including their own responses.
class PrayerRequestScreen extends ConsumerStatefulWidget {
  const PrayerRequestScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<PrayerRequestScreen> createState() =>
      _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends ConsumerState<PrayerRequestScreen> {
  final _input = TextEditingController();
  var _sending = false;
  var _praying = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(prayerResponsesProvider(widget.requestId).notifier)
          .add(text);
      _input.clear();
    } catch (_) {
      if (mounted) {
        showErrorSnack(
          context,
          'Your response was not sent. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Reuses the wall's once-only "I prayed" logic (activity and badges).
  Future<void> _pray(PrayerRequest r) async {
    if (_praying) return;
    setState(() => _praying = true);
    try {
      final earned = await ref
          .read(prayerRequestsProvider(r.communityId).notifier)
          .togglePrayed(r.id);
      if (mounted && earned.isNotEmpty) {
        ref.read(badgeQueueProvider.notifier).addAll(earned);
        showQueuedBadges(context, ref);
      }
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _praying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fetched = ref.watch(prayerRequestByIdProvider(widget.requestId));
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final base = fetched.valueOrNull;
    // Live state ("I prayed", count) from the community wall when loaded.
    final live = base == null
        ? null
        : ref
              .watch(prayerRequestsProvider(base.communityId))
              .valueOrNull
              ?.where((r) => r.id == base.id)
              .firstOrNull;
    final request = live ?? base;

    return AmberHeaderScaffold(
      title: 'Prayer request',
      body: switch (fetched) {
        AsyncValue(isLoading: true, hasValue: false) => const Skeleton(
          showHeader: false,
          cardCount: 1,
        ),
        AsyncValue(hasError: true, hasValue: false) => ErrorView(
          onRetry: () =>
              ref.invalidate(prayerRequestByIdProvider(widget.requestId)),
        ),
        _ when request == null => const EmptyState(
          icon: Icons.volunteer_activism_outlined,
          title: 'Prayer request not available',
          body: 'It was removed or is no longer visible to you.',
        ),
        _ => _Body(
          request: request,
          online: online,
          praying: _praying,
          onPray: () => _pray(request),
        ),
      },
      bottomBar: request == null
          ? null
          : MessageInputBar(
              controller: _input,
              onSend: _send,
              hintText: online
                  ? 'Write an encouraging response'
                  : 'You are offline',
              sendLabel: 'Send response',
              enabled: online && !_sending,
            ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.request,
    required this.online,
    required this.praying,
    required this.onPray,
  });

  final PrayerRequest request;
  final bool online;
  final bool praying;
  final VoidCallback onPray;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref
        .watch(communityByIdProvider(request.communityId))
        .valueOrNull;
    final responses = ref.watch(prayerResponsesProvider(request.id));
    final author = request.anonymous
        ? 'Anonymous'
        : (request.authorName ?? 'Member');
    final meta = [
      formatRelativeTime(request.createdAt),
      ?community?.name,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const OfflineBanner(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(
                    initials: request.anonymous ? '?' : initialsOf(author),
                    size: _avatarSize,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author, style: AppTextStyles.cardTitle),
                        Text(
                          meta,
                          style: AppTextStyles.fieldLabel.copyWith(
                            color: AppColors.placeholder,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.body,
                style: AppTextStyles.body.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              Semantics(
                toggled: request.prayedByMe,
                child: request.prayedByMe
                    ? AppPrimaryButton(
                        label: 'I prayed',
                        height: 48,
                        isLoading: praying,
                        onPressed: online && !praying ? onPray : null,
                      )
                    : AppSecondaryButton(
                        label: 'I prayed',
                        height: 48,
                        isLoading: praying,
                        onPressed: online && !praying ? onPray : null,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                prayedLabel(request.prayedCount),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Responses', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 8),
        ...switch (responses) {
          AsyncValue(isLoading: true, hasValue: false) => [
            const Skeleton(showHeader: false, cardCount: 1),
          ],
          AsyncValue(hasError: true, hasValue: false) => [
            ErrorView(
              onRetry: () =>
                  ref.invalidate(prayerResponsesProvider(request.id)),
            ),
          ],
          _ when (responses.valueOrNull ?? const []).isEmpty => [
            Text(
              'No responses yet. Be the first to encourage them.',
              style: AppTextStyles.body,
            ),
          ],
          _ => [for (final r in responses.requireValue) _ResponseRow(r)],
        },
      ],
    );
  }
}

class _ResponseRow extends StatelessWidget {
  const _ResponseRow(this.r);

  final PrayerResponse r;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(
            initials: r.anonymous ? '?' : initialsOf(r.displayName),
            size: _avatarSize,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.displayName, style: AppTextStyles.bodyMedium),
                Text(r.body, style: AppTextStyles.body),
                const SizedBox(height: 4),
                Text(
                  formatRelativeTime(r.createdAt),
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
