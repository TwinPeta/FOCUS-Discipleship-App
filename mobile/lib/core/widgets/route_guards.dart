import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/community/domain/membership.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../theme/app_colors.dart';

/// Wraps a screen that needs a created profile. Used by `/general-feed`,
/// `/messages`, `/compose` and `/activity`.
class RequireProfile extends ConsumerWidget {
  const RequireProfile({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
      return const _GuardLoading();
    }
    return child;
  }
}

/// Wraps a screen that needs an approved membership in [communityId]. Used
/// by every `/community/:id/*` route.
class RequireApprovedMembership extends ConsumerWidget {
  const RequireApprovedMembership({
    super.key,
    required this.communityId,
    required this.child,
  });

  final String communityId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(membershipProvider);
    if (membershipAsync.isLoading && !membershipAsync.hasValue) {
      return const _GuardLoading();
    }

    final membership = membershipAsync.valueOrNull ?? Membership.empty;
    final isAuthorized =
        membership.status == MembershipStatus.approved &&
        membership.communityId == communityId;

    if (!isAuthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/communities');
      });
      return const _GuardLoading();
    }
    return child;
  }
}

class _GuardLoading extends StatelessWidget {
  const _GuardLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}
