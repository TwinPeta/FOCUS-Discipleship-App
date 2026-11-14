/// An admin-set suspension. It blocks the whole app (screen 60) until
/// [until], then releases on its own.
class Suspension {
  const Suspension({required this.reason, required this.until});

  final String reason;
  final DateTime until;

  bool isActiveAt(DateTime now) => now.isBefore(until);
}
