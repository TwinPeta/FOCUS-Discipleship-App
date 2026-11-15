import 'package:focus_1/features/community/data/membership_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/notifications/data/notification_repository.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';

class FakeMembershipRepository implements MembershipRepository {
  FakeMembershipRepository({
    this.latency = const Duration(milliseconds: 400),
    this.notifications,
  });

  final Duration latency;

  /// Approve/decline emit a notification record for the student.
  final NotificationRepository? notifications;
  Membership _membership = Membership.empty;
  Future<Membership>? _inFlightRequest;

  @override
  Future<Membership> getMembership() async {
    await Future.delayed(latency);
    return _membership;
  }

  @override
  Future<Membership> requestToJoin(String communityId) {
    // Two rapid taps share one in-flight request.
    return _inFlightRequest ??= _request(communityId)
        .whenComplete(() => _inFlightRequest = null);
  }

  Future<Membership> _request(String communityId) async {
    await Future.delayed(latency);
    if (_membership.isActive) {
      if (_membership.communityId == communityId &&
          _membership.status == MembershipStatus.pending) {
        return _membership;
      }
      throw MembershipLimitReached(_membership.communityId);
    }
    // A rejected request must be acknowledged (-> none) before a new one.
    if (_membership.status == MembershipStatus.rejected) {
      _membership = _membership.transitionTo(MembershipStatus.none);
    }
    _membership = _membership.transitionTo(
      MembershipStatus.pending,
      communityId: communityId,
    );
    return _membership;
  }

  @override
  Future<Membership> debugApprove() async {
    await Future.delayed(latency);
    _membership = _membership.transitionTo(MembershipStatus.approved);
    await notifications?.add(
      type: NotificationType.requestApproved,
      title: 'Your request was approved',
      targetRoute: '/request/approved',
    );
    return _membership;
  }

  @override
  Future<Membership> reject({String? message}) async {
    await Future.delayed(latency);
    _membership = _membership.transitionTo(
      MembershipStatus.rejected,
      message: message,
    );
    await notifications?.add(
      type: NotificationType.requestDeclined,
      title: 'Your request was not accepted',
      targetRoute: '/request/declined',
    );
    return _membership;
  }

  @override
  Future<Membership> cancelRequest() async {
    await Future.delayed(latency);
    if (_membership.status != MembershipStatus.pending) {
      throw IllegalMembershipTransition(
        _membership.status,
        MembershipStatus.none,
      );
    }
    _membership = _membership.transitionTo(MembershipStatus.none);
    return _membership;
  }

  @override
  Future<Membership> leave() async {
    await Future.delayed(latency);
    if (_membership.status != MembershipStatus.approved) {
      throw IllegalMembershipTransition(
        _membership.status,
        MembershipStatus.none,
      );
    }
    _membership = _membership.transitionTo(MembershipStatus.none);
    return _membership;
  }

  @override
  Future<Membership> markResultSeen() async {
    await Future.delayed(latency);
    _membership = _membership.markResultSeen();
    return _membership;
  }

  @override
  Future<Membership> clear() async {
    await Future.delayed(latency);
    if (_membership.status == MembershipStatus.none) return _membership;
    _membership = _membership.transitionTo(MembershipStatus.none);
    return _membership;
  }
}
