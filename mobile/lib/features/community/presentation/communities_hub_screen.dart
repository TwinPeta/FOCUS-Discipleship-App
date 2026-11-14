import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/info_banner.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/community.dart';
import '../domain/membership.dart';
import 'providers/community_providers.dart';
import 'providers/membership_provider.dart';
import 'widgets/community_list_card.dart';
import 'widgets/community_search_field.dart';
import 'widgets/general_community_card.dart';
import 'widgets/hub_header.dart';
import 'widgets/hub_specific_slot.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../../core/widgets/states/error_view.dart';

/// Screen 3 of the brief: Communities hub, including the 3b "pending"
/// variant of the specific-community slot.
class CommunitiesHubScreen extends ConsumerStatefulWidget {
  const CommunitiesHubScreen({super.key});

  @override
  ConsumerState<CommunitiesHubScreen> createState() =>
      _CommunitiesHubScreenState();
}

class _CommunitiesHubScreenState extends ConsumerState<CommunitiesHubScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Community> _filter(List<Community> communities, String query) {
    if (query.trim().isEmpty) return communities;
    final lower = query.trim().toLowerCase();
    return communities.where((community) {
      return community.name.toLowerCase().contains(lower) ||
          (community.meetingDay?.toLowerCase().contains(lower) ?? false) ||
          (community.room?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  bool _resultShown = false;

  /// Shows the approved/declined result once, the first time the hub sees
  /// an unseen result (the screen itself marks it seen).
  void _maybeShowResult(Membership membership) {
    if (_resultShown || !membership.hasUnseenResult) return;
    _resultShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.push(
          membership.status == MembershipStatus.approved
              ? '/request/approved'
              : '/request/declined',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(child: Center(child: Text('No profile yet.'))),
      );
    }

    final membershipAsync = ref.watch(membershipProvider);

    if (membershipAsync.isLoading && !membershipAsync.hasValue) {
      return const Scaffold(backgroundColor: AppColors.page, body: Skeleton());
    }

    final membership = membershipAsync.valueOrNull ?? Membership.empty;
    _maybeShowResult(membership);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HubHeader(profile: profile),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My communities', style: AppTextStyles.sectionHeading),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(child: GeneralCommunityCard()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HubSpecificSlot(membership: membership),
                          ),
                        ],
                      ),
                    ),
                    if (membership.status != MembershipStatus.approved) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Find a specific community',
                        style: AppTextStyles.sectionHeading,
                      ),
                      const SizedBox(height: 12),
                      InfoBanner(
                        child: Text.rich(
                          TextSpan(
                            style: AppTextStyles.body.copyWith(fontSize: 13.5),
                            children: [
                              if (membership.status == MembershipStatus.pending)
                                const TextSpan(
                                  text:
                                      'Request sent to the super-mentor. Other communities are '
                                      'locked until you get an answer. You can join ',
                                )
                              else
                                const TextSpan(text: 'You can join '),
                              const TextSpan(
                                text: 'only one',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const TextSpan(
                                text: ' specific community. Choose the one that fits you best.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CommunitySearchField(
                        controller: _searchController,
                        enabled: membership.status != MembershipStatus.pending,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: 14),
                      Consumer(
                        builder: (context, ref, _) {
                          final communitiesAsync = ref.watch(
                            specificCommunitiesProvider,
                          );
                          return communitiesAsync.when(
                            loading: () =>
                                const Skeleton(showHeader: false, cardCount: 2),
                            error: (error, stackTrace) => ErrorView(
                              onRetry: () =>
                                  ref.invalidate(specificCommunitiesProvider),
                            ),
                            data: (communities) {
                              var visible = communities;
                              if (membership.status ==
                                  MembershipStatus.pending) {
                                visible = communities
                                    .where(
                                      (c) => c.id != membership.communityId,
                                    )
                                    .toList();
                              }
                              final filtered = _filter(visible, _query);

                              if (filtered.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No communities match your search.',
                                      style: AppTextStyles.body,
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  for (var i = 0; i < filtered.length; i++) ...[
                                    CommunityListCard(
                                      community: filtered[i],
                                      tileColor: i == 0
                                          ? AppColors.amber
                                          : AppColors.honey,
                                      enabled:
                                          membership.status !=
                                          MembershipStatus.pending,
                                    ),
                                    if (i != filtered.length - 1)
                                      const SizedBox(height: 12),
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
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
