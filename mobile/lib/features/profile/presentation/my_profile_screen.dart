import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/dashed_rrect_painter.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../community/domain/membership.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';

/// Screen 2b of the brief: "My profile".
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Back',
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/communities'),
                ),
                Expanded(
                  child: Center(
                    child: Text('No profile yet.', style: AppTextStyles.body),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(profile: profile),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailsCard(profile: profile),
                    const SizedBox(height: 28),
                    Text('My communities', style: AppTextStyles.sectionHeading),
                    const SizedBox(height: 12),
                    _GeneralCommunityRow(profile: profile),
                    const SizedBox(height: 12),
                    const _SpecificCommunitySlot(),
                    const SizedBox(height: 24),
                    const _ActivityRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        children: [
          Row(
            children: [
              RoundIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/communities'),
              ),
              const SizedBox(width: 52),
              Expanded(
                child: Text(
                  'My profile',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              RoundIconButton(
                icon: Icons.edit_outlined,
                semanticLabel: 'Edit profile',
                onPressed: () => context.push('/settings/profile'),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.settings_outlined,
                semanticLabel: 'Settings',
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              InitialsAvatar(
                initials: profile.initials,
                photoPath: profile.photoPath,
                size: 112,
                backgroundColor: AppColors.white,
                borderColor: AppColors.white,
                borderWidth: 4,
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: RoundIconButton(
                  icon: Icons.photo_camera_outlined,
                  semanticLabel: 'Change profile photo',
                  size: 44,
                  borderColor: AppColors.ink,
                  borderWidth: 2,
                  onPressed: () => context.push('/settings/profile'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.fullName,
            style: AppTextStyles.profileName,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '@${profile.username}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Email', profile.email),
      ('Phone', profile.phone),
      ('Country', profile.country),
      (
        profile.institutionType == InstitutionType.university
            ? 'University'
            : 'High school',
        profile.institutionName,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Text(
                    rows[i].$1,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.inkDeemphasized80,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, color: AppColors.cream),
          ],
        ],
      ),
    );
  }
}

class _GeneralCommunityRow extends StatelessWidget {
  const _GeneralCommunityRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/general-feed'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.honey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.groups_rounded, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('General community', style: AppTextStyles.cardTitle),
                  Text(
                    'Joined automatically',
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _SpecificCommunitySlot extends ConsumerWidget {
  const _SpecificCommunitySlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(membershipProvider);
    final membership = membershipAsync.valueOrNull;

    if (membership != null &&
        membership.status == MembershipStatus.approved &&
        membership.communityId != null) {
      final communityAsync = ref.watch(
        communityByIdProvider(membership.communityId!),
      );
      return communityAsync.when(
        loading: () => const SizedBox(height: 72),
        error: (error, stackTrace) => const _PickCommunityRow(),
        data: (community) => InkWell(
          onTap: () => context.push('/community/${community.id}/feed'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    community.initials,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(community.name, style: AppTextStyles.cardTitle),
                      Text(
                        'Your specific community',
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
              ],
            ),
          ),
        ),
      );
    }

    return const _PickCommunityRow();
  }
}

class _PickCommunityRow extends StatelessWidget {
  const _PickCommunityRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/communities'),
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: const DashedRRectPainter(radius: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Pick a specific community',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/activity'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My activity & badges', style: AppTextStyles.cardTitle),
                  Text(
                    'See your history and progress',
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}
