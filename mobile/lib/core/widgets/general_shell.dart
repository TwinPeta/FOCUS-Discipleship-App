import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/domain/membership.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../theme/app_colors.dart';
import '../utils/online_count.dart';
import 'community_header_chrome.dart';

/// The amber header used by the General feed: same chrome as
/// [CommunityShell] but without a tab bar. Tapping the "specific community"
/// segment goes to the user's approved community, or to the hub if they
/// don't have one yet.
class GeneralShell extends ConsumerWidget {
  const GeneralShell({super.key, required this.body, this.floatingActionButton});

  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(membershipProvider).valueOrNull ?? Membership.empty;
    final hasApprovedSpecific =
        membership.status == MembershipStatus.approved &&
        membership.communityId != null;

    return Scaffold(
      backgroundColor: AppColors.page,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CommunityHeaderChrome(
              title: 'General community',
              onlineCount: estimateOnlineCount('general-community'),
              generalSelected: true,
              specificLabel: 'Specific community',
              onSelectGeneral: () {},
              onSelectSpecific: () {
                if (hasApprovedSpecific) {
                  context.push('/community/${membership.communityId}/feed');
                } else {
                  context.push('/communities');
                }
              },
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
