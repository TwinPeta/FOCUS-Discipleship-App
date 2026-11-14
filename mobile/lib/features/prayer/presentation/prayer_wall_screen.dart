import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/initials.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../../core/widgets/tab_section_header.dart';
import '../../learning/presentation/learning_providers.dart';
import '../../learning/presentation/widgets/viewer_parts.dart';
import '../domain/prayer_request.dart';
import 'providers/prayer_providers.dart';

/// Screen 14: Prayer wall tab inside [CommunityShell].
class PrayerWallScreen extends ConsumerWidget {
  const PrayerWallScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = prayerRequestsProvider(communityId);
    final requestsAsync = ref.watch(provider);

    if (requestsAsync.isLoading && !requestsAsync.hasValue) {
      return const Skeleton(showHeader: false);
    }
    if (requestsAsync.hasError && !requestsAsync.hasValue) {
      return ErrorView(onRetry: () => ref.invalidate(provider));
    }
    final requests = requestsAsync.valueOrNull ?? const <PrayerRequest>[];
    void newRequest() => context.push('/community/$communityId/prayer/new');

    Future<void> onPrayed(PrayerRequest request) async {
      try {
        final newlyEarned = await ref
            .read(provider.notifier)
            .togglePrayed(request.id);
        if (!context.mounted || newlyEarned.isEmpty) return;
        ref.read(badgeQueueProvider.notifier).addAll(newlyEarned);
        showQueuedBadges(context, ref);
      } catch (_) {
        if (context.mounted) showErrorSnack(context);
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(provider.future),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: 1 + (requests.isEmpty ? 1 : requests.length),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TabSectionHeader(
                title: 'Prayer wall',
                actionLabel: 'Share a request',
                onAction: newRequest,
              ),
            );
          }
          if (requests.isEmpty) {
            return EmptyState(
              icon: Icons.volunteer_activism_outlined,
              title: 'No prayer requests yet',
              body: 'Be the first to share one.',
              actionLabel: 'Share a request',
              onAction: newRequest,
            );
          }
          final request = requests[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PrayerCard(
              key: ValueKey(request.id),
              request: request,
              onPrayedTap: () => onPrayed(request),
              onRespondTap: () => context.push('/prayer/${request.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    super.key,
    required this.request,
    required this.onPrayedTap,
    required this.onRespondTap,
  });

  final PrayerRequest request;
  final VoidCallback onPrayedTap;
  final VoidCallback onRespondTap;

  @override
  Widget build(BuildContext context) {
    final name = request.anonymous ? 'Anonymous' : (request.authorName ?? '');
    return Container(
      padding: const EdgeInsets.all(14),
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
              AvatarWithPresence(
                initials: request.anonymous ? '?' : initialsOf(name),
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatRelativeTime(request.createdAt),
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.inkDeemphasized80,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(request.body, style: AppTextStyles.body.copyWith(height: 1.4)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              PillButton(
                label: request.prayedCount > 0
                    ? '${request.prayedCount} prayed'
                    : 'I prayed',
                semanticLabel: request.prayedByMe
                    ? 'You prayed. ${request.prayedCount} prayed in total'
                    : 'I prayed. ${request.prayedCount} prayed so far',
                filled: request.prayedByMe,
                onTap: onPrayedTap,
              ),
              PillButton(label: 'Respond', onTap: onRespondTap),
            ],
          ),
        ],
      ),
    );
  }
}
