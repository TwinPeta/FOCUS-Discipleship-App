import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../domain/membership.dart';
import '../domain/person.dart';
import '../../profile/presentation/profile_providers.dart';
import 'providers/community_providers.dart';
import 'providers/membership_provider.dart';
import 'widgets/community_cover.dart';
import 'widgets/leadership_row.dart';

/// Screen 4 of the brief: Community detail & request to join.
class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  bool _isRequesting = false;

  Future<void> _requestToJoin() async {
    setState(() => _isRequesting = true);
    await ref
        .read(membershipProvider.notifier)
        .requestToJoin(widget.communityId);
    if (!mounted) return;
    setState(() => _isRequesting = false);
    context.go('/communities');
  }

  @override
  Widget build(BuildContext context) {
    final communityAsync = ref.watch(communityByIdProvider(widget.communityId));
    final profile = ref.watch(currentProfileProvider);
    final membershipAsync = ref.watch(membershipProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: communityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Could not load this community.',
            style: AppTextStyles.body,
          ),
        ),
        data: (community) {
          final membership = membershipAsync.valueOrNull ?? Membership.empty;
          final alreadyHasMembership =
              membership.status == MembershipStatus.pending ||
              membership.status == MembershipStatus.approved;

          return SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CommunityCover(
                          community: community,
                          institutionName:
                              profile?.institutionName ?? '[University]',
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                community.description,
                                style: AppTextStyles.body.copyWith(
                                  height: 1.55,
                                  color: AppColors.inkDeemphasized85,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'In-person meeting',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.calendar_today_outlined,
                                label:
                                    '${community.meetingDay ?? "[Meeting day]"} · ${community.meetingTime ?? "[Time]"}',
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.place_outlined,
                                label:
                                    community.room ??
                                    '[Meeting room, building]',
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Leadership',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              LeadershipRow(
                                person:
                                    community.superMentor ??
                                    const Person(
                                      id: '',
                                      name: '[Super-mentor name]',
                                      role: PersonRole.superMentor,
                                    ),
                                roleLabel: 'Super-mentor',
                                color: AppColors.amber,
                              ),
                              for (final mentor in community.mentors)
                                LeadershipRow(
                                  person: mentor,
                                  roleLabel: 'Mentor',
                                  color: AppColors.honey,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _RequestBar(
                  isLoading: _isRequesting,
                  disabled: alreadyHasMembership,
                  onPressed: alreadyHasMembership ? null : _requestToJoin,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestBar extends StatelessWidget {
  const _RequestBar({
    required this.isLoading,
    required this.disabled,
    required this.onPressed,
  });

  final bool isLoading;
  final bool disabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.cream, width: 1)),
      ),
      child: Column(
        children: [
          AppPrimaryButton(
            label: 'Request to join',
            isLoading: isLoading,
            onPressed: onPressed,
          ),
          const SizedBox(height: 10),
          Text(
            disabled
                ? 'You already have a pending request or have joined a specific community.'
                : 'You can join only one specific community. Your request goes to the '
                      'super-mentor for approval, and you will be notified.',
            style: AppTextStyles.fieldLabel.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.inkDeemphasized80,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
