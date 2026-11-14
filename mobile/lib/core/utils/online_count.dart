/// Deterministic placeholder "online now" count derived from an id, so each
/// community shows a stable but varied number without real presence data.
int estimateOnlineCount(String seed) {
  final hash = seed.codeUnits.fold<int>(0, (total, unit) => total + unit);
  return 6 + (hash % 18);
}
