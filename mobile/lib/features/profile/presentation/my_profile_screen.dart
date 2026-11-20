import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/dashed_rrect_painter.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/round_icon_button.dart';
import 'widgets/join_photo_picker.dart';
import '../../community/domain/membership.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/theme/app_gradients.dart';

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
                    Text('My caregroups', style: AppTextStyles.sectionHeading),
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
      decoration: BoxDecoration(
        gradient: AppGradients.hubHeader,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
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
                icon: Icons.settings_outlined,
                semanticLabel: 'Settings',
                onPressed: () => context.push('/settings'),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.edit_outlined,
                semanticLabel: 'Edit profile',
                onPressed: () => context.push('/settings/profile'),
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
                child: _ChangePhotoButton(profile: profile),
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
      (profile.institutionType.label, profile.institutionName),
      if (profile.yearOfStudy != null)
        ('Year of study', 'Year ${profile.yearOfStudy}'),
      if (profile.homeChurch case final church?) ...[
        ('Home church', church.name),
        ('Church location', church.location),
        ('Pastor', church.pastor),
      ],
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
              Divider(height: 1, color: AppColors.cream),
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
              child: Icon(Icons.groups_rounded, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('General caregroup', style: AppTextStyles.cardTitle),
                  Text(
                    'Joined automatically',
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.ink),
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
              gradient: AppGradients.brand,
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
                        'Your specific caregroup',
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.ink),
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
                  'Pick a specific caregroup',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.ink),
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
          gradient: AppGradients.brand,
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
            Icon(Icons.chevron_right_rounded, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

/// The camera on the avatar: pick a photo, upload it and show it.
class _ChangePhotoButton extends ConsumerStatefulWidget {
  const _ChangePhotoButton({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ChangePhotoButton> createState() => _ChangePhotoButtonState();
}

class _ChangePhotoButtonState extends ConsumerState<_ChangePhotoButton> {
  var _saving = false;

  Future<void> _change() async {
    if (_saving) return;
    final path = await choosePhoto(context, ref);
    if (path == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .save(widget.profile.copyWith(photoPath: path));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Photo updated')));
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, 'Could not upload the photo. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saving) {
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.ink,
        ),
      );
    }
    return RoundIconButton(
      icon: Icons.photo_camera_outlined,
      semanticLabel: 'Change profile photo',
      size: 44,
      borderColor: AppColors.ink,
      borderWidth: 2,
      onPressed: _change,
    );
  }
}
