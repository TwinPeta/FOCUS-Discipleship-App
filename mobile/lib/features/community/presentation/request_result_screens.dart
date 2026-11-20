import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/celebration_screen.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../messaging/data/messaging_repository.dart';
import '../../messaging/presentation/providers/messaging_providers.dart';
import '../domain/community.dart';
import '../domain/membership.dart';
import 'providers/community_providers.dart';
import 'providers/membership_provider.dart';

/// Marks the one-time result as seen when shown, and resolves the
/// community the result is about.
mixin _ResultScreen<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// The status this screen is about.
  MembershipStatus get expected;

  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Opened from a notification or a phone push, the decision may not be
      // in the membership yet (socket missed it): re-read it first.
      Membership? membership;
      try {
        membership = await ref.refresh(membershipProvider.future);
      } catch (_) {
        membership = ref.read(membershipProvider).valueOrNull;
      }
      if (!mounted) return;
      if (membership != null && membership.hasUnseenResult) {
        ref.read(membershipProvider.notifier).markResultSeen().ignore();
      }
    });
  }

  /// An old notification (already acknowledged, or about a request the
  /// student has moved on from) goes to the hub instead of an error.
  Widget _toHub() {
    if (!_leaving) {
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/communities');
      });
    }
    return const Scaffold(body: Skeleton());
  }

  Widget withCommunity(Widget Function(Membership, Community) build) {
    final async = ref.watch(membershipProvider);
    final membership = async.valueOrNull;
    if (membership == null) {
      return const Scaffold(body: Skeleton());
    }
    final id = membership.communityId;
    if (membership.status != expected || id == null) {
      return async.isLoading ? const Scaffold(body: Skeleton()) : _toHub();
    }
    return ref
        .watch(communityByIdProvider(id))
        .when(
          loading: () => const Scaffold(body: Skeleton()),
          error: (e, s) => ErrorScreen(
            onRetry: () => ref.invalidate(communityByIdProvider(id)),
          ),
          data: (community) => build(membership, community),
        );
  }
}

/// Screen 27: Request approved (`/request/approved`), shown once.
class RequestApprovedScreen extends ConsumerStatefulWidget {
  const RequestApprovedScreen({super.key});

  @override
  ConsumerState<RequestApprovedScreen> createState() =>
      _RequestApprovedScreenState();
}

class _RequestApprovedScreenState extends ConsumerState<RequestApprovedScreen>
    with _ResultScreen {
  @override
  MembershipStatus get expected => MembershipStatus.approved;

  bool _opening = false;

  Future<void> _sayHello(Community community) async {
    final mentor = community.superMentor;
    if (mentor == null || _opening) return;
    setState(() => _opening = true);
    try {
      final thread = await ref
          .read(threadRepositoryProvider)
          .openOrCreateThread(mentor, mentor.role.label);
      ref.invalidate(threadsProvider);
      if (mounted) unawaited(context.push('/messages/${thread.id}'));
    } on MessagingRestricted {
      if (mounted) showErrorSnack(context, MessagingRestricted.message);
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(messagingRestrictedProvider);
    return withCommunity((membership, community) {
      final mentor = community.superMentor;
      final canHello =
          mentor != null &&
          ref.read(threadRepositoryProvider).canMessage(mentor);
      return CelebrationScreen(
        icon: Icons.celebration_rounded,
        title: 'You are in!',
        body: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Welcome to '),
              TextSpan(
                text: community.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: mentor == null
                    ? '. Your request was approved.'
                    : '. ${mentor.name} approved your request.',
              ),
            ],
          ),
        ),
        extra: [
          CelebrationInfoRow(
            icon: Icons.calendar_today_outlined,
            label:
                '${community.meetingDay ?? 'Meeting day to be confirmed'}'
                '${community.meetingTime == null ? '' : ' · ${community.meetingTime}'}',
          ),
          CelebrationInfoRow(
            icon: Icons.place_outlined,
            label: community.room ?? 'Room to be confirmed',
          ),
        ],
        actions: [
          AppPrimaryButton(
            label: 'Open my caregroup',
            onPressed: () => context.go('/community/${community.id}/feed'),
          ),
          if (mentor != null)
            AppSecondaryButton(
              label: canHello
                  ? 'Say hello to my mentor'
                  : MessagingRestricted.message,
              isLoading: _opening,
              onPressed: canHello ? () => _sayHello(community) : null,
            ),
        ],
      );
    });
  }
}

/// Screen 28: Request declined (`/request/declined`), shown once.
class RequestDeclinedScreen extends ConsumerStatefulWidget {
  const RequestDeclinedScreen({super.key});

  @override
  ConsumerState<RequestDeclinedScreen> createState() =>
      _RequestDeclinedScreenState();
}

class _RequestDeclinedScreenState extends ConsumerState<RequestDeclinedScreen>
    with _ResultScreen {
  @override
  MembershipStatus get expected => MembershipStatus.rejected;

  bool _busy = false;

  Future<void> _chooseAnother() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = ref.read(membershipProvider).valueOrNull?.status;
      if (status == MembershipStatus.rejected) {
        await ref.read(membershipProvider.notifier).clear();
      }
      if (mounted) context.go('/communities');
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return withCommunity((membership, community) {
      final message = membership.message;
      return CelebrationScreen(
        icon: Icons.info_outline_rounded,
        iconBackground: AppColors.cream,
        title: 'Request not accepted',
        body: Column(
          children: [
            Text(
              'The super-mentor could not add you to ${community.name} this '
              'time.${message == null || message.isEmpty ? '' : ' "$message"'}',
            ),
            const SizedBox(height: 12),
            const Text(
              'You can request another specific caregroup. You are still '
              'part of your general campus caregroup.',
            ),
          ],
        ),
        actions: [
          AppPrimaryButton(
            label: 'Choose another caregroup',
            isLoading: _busy,
            onPressed: _chooseAnother,
          ),
          AppSecondaryButton(
            label: 'Go to my campus',
            onPressed: () => context.go('/general-feed'),
          ),
        ],
      );
    });
  }
}
