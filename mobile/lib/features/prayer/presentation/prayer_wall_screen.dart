import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../domain/prayer_request.dart';
import 'providers/prayer_providers.dart';

/// Screen 14: Prayer wall tab inside [CommunityShell].
class PrayerWallScreen extends ConsumerWidget {
  const PrayerWallScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(prayerRequestsProvider(communityId));

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(prayerRequestsProvider(communityId)),
      child: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text('Could not load the prayer wall.', style: AppTextStyles.body),
            ),
          ],
        ),
        data: (requests) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Row(
                children: [
                  Text(
                    'Prayer wall',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Share a request',
                    child: InkWell(
                      onTap: () => context.push('/community/$communityId/prayer/new'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add, color: AppColors.ink),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (requests.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No prayer requests yet. Be the first to share one.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                for (var i = 0; i < requests.length; i++) ...[
                  _PrayerCard(
                    request: requests[i],
                    onPrayedTap: () async {
                      final newlyEarned = await ref
                          .read(prayerRequestsProvider(communityId).notifier)
                          .togglePrayed(requests[i].id);
                      if (!context.mounted) return;
                      for (final badge in newlyEarned) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('New badge earned: ${badge.name}!')),
                        );
                      }
                    },
                  ),
                  if (i != requests.length - 1) const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.request, required this.onPrayedTap});

  final PrayerRequest request;
  final VoidCallback onPrayedTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWithPresence(
                initials: request.anonymous ? '?' : (request.authorName ?? '?'),
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.anonymous ? 'Anonymous' : (request.authorName ?? ''),
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
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
          const SizedBox(height: 12),
          Row(
            children: [
              _PillButton(
                label: request.prayedCount > 0
                    ? '${request.prayedCount} prayed'
                    : 'I prayed',
                filled: request.prayedByMe,
                onTap: onPrayedTap,
              ),
              const SizedBox(width: 10),
              _PillButton(
                label: 'Respond',
                filled: false,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Responding coming soon')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: filled,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.amber : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: AppColors.ink, width: 2),
          ),
          child: Text(
            label,
            style: AppTextStyles.chip.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
