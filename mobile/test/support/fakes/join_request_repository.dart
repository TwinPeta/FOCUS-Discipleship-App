import 'package:focus_1/features/community/data/join_request_repository.dart';
import 'package:focus_1/features/community/domain/join_request.dart';
import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/notifications/data/notification_repository.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';

class FakeJoinRequestRepository implements JoinRequestRepository {
  FakeJoinRequestRepository({
    this.latency = const Duration(milliseconds: 400),
    this.notifications,
    List<JoinRequest>? seed,
  }) : _items = [...(seed ?? _seed())];

  final Duration latency;
  final NotificationRepository? notifications;
  final List<JoinRequest> _items;
  final Set<String> _inFlight = {};

  static List<JoinRequest> _seed() {
    final now = DateTime.now();
    JoinRequest r(
      String id,
      String name,
      String username,
      int daysAgo, {
      String? existing,
    }) => JoinRequest(
      id: 'jr-$id',
      communityId: 'growth-circle',
      studentId: 'student-$id',
      studentName: name,
      username: username,
      institution: 'Makerere University',
      requestedAt: now.subtract(Duration(days: daysAgo)),
      existingCommunityName: existing,
    );
    return [
      r('1', 'Brian Mugisha', 'brianm', 3),
      r('2', 'Aisha Nakato', 'aisha.n', 2),
      r('3', 'Peter Ssemanda', 'peter_s', 1, existing: 'Life & Faith Circle'),
      r('4', 'Joy Atim', 'joyatim', 0),
    ];
  }

  void _requireSuperMentor(UserRole? role, String communityId) {
    if (role != UserRole.superMentor) throw NotSuperMentor(communityId);
  }

  int _indexOf(String id) {
    final i = _items.indexWhere((r) => r.id == id);
    if (i == -1) throw ArgumentError.value(id, 'id', 'unknown join request');
    return i;
  }

  @override
  Future<List<JoinRequest>> getPending(
    String communityId, {
    required UserRole? actorRole,
  }) async {
    await Future.delayed(latency);
    _requireSuperMentor(actorRole, communityId);
    final pending =
        _items
            .where((r) => r.communityId == communityId && r.isPending)
            .toList()
          ..sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
    return List.unmodifiable(pending);
  }

  @override
  Future<JoinRequest> approve(String id, {required UserRole? actorRole}) =>
      _decide(id, actorRole, approve: true);

  @override
  Future<JoinRequest> decline(
    String id, {
    required UserRole? actorRole,
    String? message,
  }) => _decide(id, actorRole, approve: false, message: message);

  Future<JoinRequest> _decide(
    String id,
    UserRole? actorRole, {
    required bool approve,
    String? message,
  }) async {
    // A second tap while the first is in flight is rejected, not repeated.
    if (!_inFlight.add(id)) throw JoinRequestNotPending(id);
    try {
      await Future.delayed(latency);
      final i = _indexOf(id);
      final request = _items[i];
      _requireSuperMentor(actorRole, request.communityId);
      if (!request.isPending) throw JoinRequestNotPending(id);
      if (approve && request.existingCommunityName != null) {
        throw StudentAlreadyInCommunity(request.existingCommunityName!);
      }
      final note = message?.trim();
      final updated = request.copyWith(
        status: approve
            ? JoinRequestStatus.approved
            : JoinRequestStatus.declined,
        message: approve || note == null || note.isEmpty ? null : note,
        seen: false,
      );
      _items[i] = updated;
      await notifications?.add(
        recipientId: request.studentId,
        type: approve
            ? NotificationType.requestApproved
            : NotificationType.requestDeclined,
        title: approve
            ? 'Your request was approved'
            : 'Your request was not accepted',
        body: updated.message,
        targetRoute: approve ? '/request/approved' : '/request/declined',
      );
      return updated;
    } finally {
      _inFlight.remove(id);
    }
  }
}
