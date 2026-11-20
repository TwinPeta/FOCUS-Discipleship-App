import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/domain/membership.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../theme/app_colors.dart';
import 'community_header_chrome.dart';
import 'community_sections.dart';
import 'states/offline_banner.dart';
import 'update_banner.dart';
import 'app_bottom_nav.dart';

/// The amber header used by the General feed: same chrome as
/// [CommunityShell] but without a tab bar. Tapping the "specific caregroup"
/// segment goes to the user's approved community, or to the hub if they
/// don't have one yet.
class GeneralShell extends ConsumerWidget {
  const GeneralShell({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.sectionLabel = 'Campus feed',
    this.activePath = 'general',
  });

  final Widget body;
  final Widget? floatingActionButton;

  /// Under the name in the header ("Campus feed", "Prayer wall", ...).
  final String sectionLabel;

  /// The "⋯" menu entry to mark as current.
  final String activePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership =
        ref.watch(membershipProvider).valueOrNull ?? Membership.empty;
    final hasApprovedSpecific =
        membership.status == MembershipStatus.approved &&
        membership.communityId != null;

    return Scaffold(
      backgroundColor: AppColors.page,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CommunityHeaderChrome(
              title: 'General caregroup',
              sectionLabel: sectionLabel,
              showBack: false,
              menuItems: communityMenuItems(
                context,
                communityId: hasApprovedSpecific
                    ? membership.communityId
                    : null,
                activePath: activePath,
              ),
            ),
            const OfflineBanner(),
            const UpdateBanner(),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
