import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/utils/password_policy.dart';

/// Reference FNV-1a 32-bit with exact BigInt arithmetic.
String _reference(String password, {String salt = 'fcu-fake-salt'}) {
  final mod = BigInt.one << 32;
  final prime = BigInt.from(0x01000193);
  var hash = BigInt.from(0x811c9dc5);
  for (var round = 0; round < 1000; round++) {
    for (final unit in '$salt:$round:$password'.codeUnits) {
      hash = (hash ^ BigInt.from(unit)) % mod;
      hash = (hash * prime) % mod;
    }
  }
  return hash.toRadixString(16);
}

void main() {
  test('matches exact FNV-1a 32-bit (web-safe arithmetic)', () {
    for (final p in ['Password1234', '', 'é ünïcode ✓', 'a' * 64]) {
      expect(fakePasswordDigest(p), _reference(p), reason: p);
    }
  });

  test('deterministic and distinguishes passwords', () {
    expect(
      fakePasswordDigest('Password1234'),
      fakePasswordDigest('Password1234'),
    );
    expect(
      fakePasswordDigest('Password1234'),
      isNot(fakePasswordDigest('Password1235')),
    );
  });
}
