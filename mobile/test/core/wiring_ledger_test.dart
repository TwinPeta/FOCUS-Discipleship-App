import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/router/placeholder_routes.dart';

/// docs/wiring.md and the placeholder route table must agree, so no control
/// added ahead of its screen can point at a route that does not exist.
void main() {
  test('every route in docs/wiring.md is a registered placeholder', () {
    final ledger = File('docs/wiring.md').readAsLinesSync();
    final registered = placeholderRoutes.map((r) => r.path).toSet();
    // Real (non-placeholder) routes the ledger may mention.
    const realRoutes = {'/profile/edit'};
    final rows = ledger.where(
      (l) =>
          l.startsWith('| ') &&
          !l.startsWith('| Source') &&
          !l.startsWith('|---'),
    );
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final cells = row.split('|').map((c) => c.trim()).toList();
      final route = RegExp(r'`([^`]+)`').firstMatch(cells[3])!.group(1)!;
      expect(
        registered.contains(route) || realRoutes.contains(route),
        isTrue,
        reason: '$route ($row)',
      );
    }
  });

  test('placeholders are owned by prompt 2 or 3', () {
    for (final r in placeholderRoutes) {
      expect([2, 3], contains(r.owner), reason: r.path);
    }
  });
}
