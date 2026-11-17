import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/fitted_box_words.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/dashed_rrect_painter.dart';
import '../../domain/membership.dart';
import '../providers/community_providers.dart';
import '../../../../core/theme/app_gradients.dart';

/// The hub's right-hand "specific community" slot, driven by
/// [MembershipStatus] (section 6.3, "Membership states of the specific
/// slot").
class HubSpecificSlot extends ConsumerWidget {
  const HubSpecificSlot({super.key, required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (membership.status) {
      case MembershipStatus.approved:
      case MembershipStatus.pending:
        if (membership.communityId == null) {
          return const _NoneSlot();
        }
        final communityAsync = ref.watch(
          communityByIdProvider(membership.communityId!),
        );
        return communityAsync.when(
          loading: () => const _LoadingSlot(),
          error: (error, stackTrace) => const _NoneSlot(),
          data: (community) {
            if (membership.status == MembershipStatus.approved) {
              return _ApprovedSlot(
                communityId: community.id,
                name: community.name,
                initials: community.initials,
              );
            }
            return _PendingSlot(
              name: community.name,
              initials: community.initials,
            );
          },
        );
      case MembershipStatus.none:
      case MembershipStatus.rejected:
        return const _NoneSlot();
    }
  }
}

class _LoadingSlot extends StatelessWidget {
  const _LoadingSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _NoneSlot extends StatelessWidget {
  const _NoneSlot();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const DashedRRectPainter(radius: 20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.honey,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.diversity_3_rounded,
                color: AppColors.ink,
                size: 22,
              ),
            ),
            const Spacer(),
            FittedBoxWords(
              'Specific community',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 4),
            Text(
              'Only 1 allowed · Pick below',
              style: AppTextStyles.body.copyWith(fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSlot extends StatelessWidget {
  const _PendingSlot({required this.name, required this.initials});

  final String name;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.honey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(initials, style: AppTextStyles.cardTitle),
          ),
          const Spacer(),
          Text(
            name,
            style: AppTextStyles.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Pending approval',
            style: AppTextStyles.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovedSlot extends StatelessWidget {
  const _ApprovedSlot({
    required this.communityId,
    required this.name,
    required this.initials,
  });

  final String communityId;
  final String name;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name, your specific community, joined',
      child: InkWell(
        onTap: () => context.push('/community/$communityId/feed'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(initials, style: AppTextStyles.cardTitle),
              ),
              const Spacer(),
              Text(
                name,
                style: AppTextStyles.cardTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Joined',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
