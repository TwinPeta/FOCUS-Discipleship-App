import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_models.dart';
import '../../features/community/domain/membership.dart';
import '../../features/community/domain/user_role.dart';
import '../../features/moderation/domain/suspension.dart';
import '../../features/moderation/domain/warning.dart';
import '../../features/profile/domain/user_profile.dart';

/// What every guard can see when deciding a redirect.
class GuardContext {
  const GuardContext({
    required this.location,
    required this.profile,
    required this.membership,
    this.session = const AsyncData<AuthSession?>(null),
    this.signUp = SignUpDraft.empty,
    this.role,
    this.pendingWarning = const AsyncData<Warning?>(null),
    this.suspension = const AsyncData<Suspension?>(null),
    this.now,
  });

  /// The full requested location (path + query).
  final Uri location;
  final AsyncValue<UserProfile?> profile;
  final AsyncValue<Membership> membership;
  final AsyncValue<AuthSession?> session;
  final SignUpDraft signUp;

  /// The user's role in their approved community, if any.
  final UserRole? role;

  /// The oldest unacknowledged moderator warning (screen 61).
  final AsyncValue<Warning?> pendingWarning;

  /// The account's suspension (screen 60), possibly already ended.
  final AsyncValue<Suspension?> suspension;

  /// Injected clock; defaults to now.
  final DateTime? now;

  bool get suspended =>
      signedIn &&
      (suspension.valueOrNull?.isActiveAt(now ?? DateTime.now()) ?? false);

  String get path => location.path;
  bool get signedIn => session.valueOrNull != null;
  bool get hasProfile => profile.valueOrNull != null;
}

/// One link of the guard chain. Returns a redirect location, or null to let
/// the next guard decide.
abstract class RouteGuard {
  const RouteGuard();
  String get name;
  String? redirect(GuardContext context);
}

/// Routes anyone may open while signed out.
const publicPaths = <String>{
  '/',
  '/join',
  '/login',
  '/forgot-password',
  '/charter',
  '/help',
  '/loading',
  '/watch',
};

bool isPublic(String path) =>
    publicPaths.contains(path) || path.startsWith('/join/');

/// Sign-up/sign-in pages a fully signed-in user is sent away from.
const _signedOutOnly = <String>{
  '/join',
  '/join/start',
  '/join/password',
  '/join/verify',
  '/join/consent',
  '/login',
  '/forgot-password',
};

/// A suspended account sees only `/suspended` (plus the charter and help)
/// until the suspension ends; then `/suspended` itself sends it home.
class SuspendedGuard extends RouteGuard {
  const SuspendedGuard();
  @override
  String get name => 'suspended';

  static const allowed = {'/suspended', '/charter', '/help'};

  @override
  String? redirect(GuardContext context) {
    if (context.suspended) {
      return allowed.contains(context.path) ? null : '/suspended';
    }
    return context.path == '/suspended' ? '/communities' : null;
  }
}

/// An unacknowledged moderator warning is shown before anything else
/// except a suspension; the charter stays readable.
class UnacknowledgedWarningGuard extends RouteGuard {
  const UnacknowledgedWarningGuard();
  @override
  String get name => 'unacknowledgedWarning';

  @override
  String? redirect(GuardContext context) {
    if (!context.signedIn) return null;
    final warning = context.pendingWarning.valueOrNull;
    if (warning == null) return null;
    final target = '/warning/${warning.id}';
    if (context.path == target || context.path == '/charter') return null;
    return target;
  }
}

/// No session -> the landing page (public pages and Back to landing stay
/// reachable).
class SignedOutGuard extends RouteGuard {
  const SignedOutGuard();
  @override
  String get name => 'signedOut';
  @override
  String? redirect(GuardContext context) {
    if (isPublic(context.path)) return null;
    return context.signedIn ? null : '/';
  }
}

/// Sign-up steps run in order, and a signed-in account without a profile
/// finishes onboarding first. A complete account skips sign-up/sign-in.
class OnboardingIncompleteGuard extends RouteGuard {
  const OnboardingIncompleteGuard();
  @override
  String get name => 'onboardingIncomplete';
  @override
  String? redirect(GuardContext context) {
    final path = context.path;
    if (context.signedIn) {
      if (!context.hasProfile && !path.startsWith('/join')) return '/join';
      if (context.hasProfile && _signedOutOnly.contains(path)) {
        return '/communities';
      }
      return null;
    }
    final draft = context.signUp;
    return switch (path) {
      '/join/password' when !draft.hasDetails => '/join',
      '/join/verify' when !draft.hasPassword => '/join/password',
      '/join/consent' when !draft.emailVerified => '/join/verify',
      // The guardian step needs the account it belongs to.
      '/join/guardian' => '/',
      _ => null,
    };
  }
}

/// `/community/:id/...` requires an approved membership in exactly `:id`;
/// the super-mentor tools additionally require that role.
class MembershipGuard extends RouteGuard {
  const MembershipGuard();
  @override
  String get name => 'membership';

  static final communityPath = RegExp(r'^/community/([^/]+)(/|$)');
  static final _manageTools = RegExp(r'^/community/[^/]+/manage(/|$)');

  @override
  String? redirect(GuardContext context) {
    final match = communityPath.firstMatch(context.path);
    if (match == null) return null;
    final membership = context.membership.valueOrNull ?? Membership.empty;
    final approved =
        membership.status == MembershipStatus.approved &&
        membership.communityId == match.group(1);
    if (!approved) return '/communities';
    if (_manageTools.hasMatch(context.path) &&
        context.role != UserRole.superMentor) {
      return '/community/${match.group(1)}/feed';
    }
    return null;
  }
}

/// Ordered: the first guard that returns a location wins.
const defaultGuardChain = <RouteGuard>[
  SuspendedGuard(),
  UnacknowledgedWarningGuard(),
  SignedOutGuard(),
  OnboardingIncompleteGuard(),
  MembershipGuard(),
];

/// Runs [guards] in order. While the session, profile or membership is
/// still loading, protected routes wait on `/loading` and come back after.
String? runGuards(GuardContext context, {List<RouteGuard>? guards}) {
  final path = context.path;
  final loading =
      context.session.isLoading ||
      context.profile.isLoading ||
      (context.membership.isLoading &&
          MembershipGuard.communityPath.hasMatch(path));
  if (path == '/loading') {
    if (loading) return null;
    final from = context.location.queryParameters['from'];
    return (from == null || from.isEmpty) ? '/' : from;
  }
  if (!isPublic(path) && loading) {
    return Uri(
      path: '/loading',
      queryParameters: {'from': context.location.toString()},
    ).toString();
  }
  for (final guard in guards ?? defaultGuardChain) {
    final target = guard.redirect(context);
    if (target != null && target != path) return target;
  }
  return null;
}
