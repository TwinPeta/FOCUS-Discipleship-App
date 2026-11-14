/// Email-code rules: a new code at most every [resendCooldown], at most
/// [maxAttempts] wrong tries, then a [lockDuration] lock. Pure and
/// clock-injectable so the rules are unit-tested.
class OtpVerifier {
  OtpVerifier({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const resendCooldown = Duration(seconds: 30);
  static const maxAttempts = 5;
  static const lockDuration = Duration(minutes: 10);

  final DateTime Function() _clock;
  String? _code;
  DateTime? _sentAt;
  DateTime? _lockedUntil;
  int _failures = 0;

  DateTime get now => _clock();

  /// Null when a code may be sent now.
  Duration? get resendAvailableIn {
    if (_sentAt == null) return null;
    final wait = resendCooldown - now.difference(_sentAt!);
    return wait > Duration.zero ? wait : null;
  }

  DateTime? get lockedUntil {
    final until = _lockedUntil;
    if (until == null || !now.isBefore(until)) return null;
    return until;
  }

  int get attemptsLeft => maxAttempts - _failures;

  /// Records a newly sent [code]. Throws [StateError] during the cooldown.
  void issue(String code) {
    if (resendAvailableIn != null) {
      throw StateError('Resend cooldown active');
    }
    _code = code;
    _sentAt = now;
  }

  OtpResult verify(String code) {
    final locked = lockedUntil;
    if (locked != null) return OtpResult.locked(locked);
    if (_lockedUntil != null) {
      // The lock expired: start a fresh set of attempts.
      _lockedUntil = null;
      _failures = 0;
    }
    if (_code != null && code == _code) {
      _failures = 0;
      return const OtpResult.verified();
    }
    _failures++;
    if (_failures >= maxAttempts) {
      _lockedUntil = now.add(lockDuration);
      return OtpResult.locked(_lockedUntil!);
    }
    return OtpResult.wrong(attemptsLeft);
  }
}

enum OtpStatus { verified, wrong, locked }

class OtpResult {
  const OtpResult.verified()
    : status = OtpStatus.verified,
      attemptsLeft = null,
      lockedUntil = null;
  const OtpResult.wrong(int this.attemptsLeft)
    : status = OtpStatus.wrong,
      lockedUntil = null;
  const OtpResult.locked(DateTime this.lockedUntil)
    : status = OtpStatus.locked,
      attemptsLeft = 0;

  final OtpStatus status;
  final int? attemptsLeft;
  final DateTime? lockedUntil;
}
